
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE TYPE "public"."Application Status" AS ENUM (
    'REJECTED',
    'DRAFT',
    'PENDING',
    'ACCEPTED',
    'WAITLISTED'
);

ALTER TYPE "public"."Application Status" OWNER TO "postgres";

COMMENT ON TYPE "public"."Application Status" IS 'Gives status of application';

CREATE TYPE "public"."Checkout Price Type" AS ENUM (
    'RSVP',
    'REGULAR'
);

ALTER TYPE "public"."Checkout Price Type" OWNER TO "postgres";

CREATE TYPE "public"."Checkout Ticket Types" AS ENUM (
    'TICKET',
    'TABLE'
);

ALTER TYPE "public"."Checkout Ticket Types" OWNER TO "postgres";

CREATE TYPE "public"."Event Ticket Status" AS ENUM (
    'NO_SALE',
    'TABLES_ONLY',
    'ATTENDEES_ONLY',
    'SELLING_ALL'
);

ALTER TYPE "public"."Event Ticket Status" OWNER TO "postgres";

COMMENT ON TYPE "public"."Event Ticket Status" IS 'Indicates whether this event is currently selling tickets';

CREATE TYPE "public"."Payment Status" AS ENUM (
    'UNPAID',
    'PAID',
    'PREBOOKED'
);

ALTER TYPE "public"."Payment Status" OWNER TO "postgres";

COMMENT ON TYPE "public"."Payment Status" IS 'Indicates whether a payment has been made';

CREATE TYPE "public"."Promo Code Status" AS ENUM (
    'INACTIVE',
    'ACTIVE'
);

ALTER TYPE "public"."Promo Code Status" OWNER TO "postgres";

COMMENT ON TYPE "public"."Promo Code Status" IS 'Promo Code Status';

CREATE TYPE "public"."Promo Code Type" AS ENUM (
    'DOLLAR',
    'PERCENT'
);

ALTER TYPE "public"."Promo Code Type" OWNER TO "postgres";

COMMENT ON TYPE "public"."Promo Code Type" IS 'What kind of promo code is this';

CREATE TYPE "public"."Question Type" AS ENUM (
    'STANDARD',
    'UNIQUE'
);

ALTER TYPE "public"."Question Type" OWNER TO "postgres";

COMMENT ON TYPE "public"."Question Type" IS 'Indicates which table to get the questions from';

CREATE TYPE "public"."Vendor Exclusivity" AS ENUM (
    'PUBLIC',
    'APPLICATIONS',
    'APPLICATIONS_NO_PAYMENT'
);

ALTER TYPE "public"."Vendor Exclusivity" OWNER TO "postgres";

COMMENT ON TYPE "public"."Vendor Exclusivity" IS 'Indicates whether vendors must apply';

CREATE OR REPLACE FUNCTION "public"."create_order"("user_id" "uuid", "event_id" "uuid", "item_id" "uuid", "item_type" "public"."Checkout Ticket Types", "purchase_quantity" integer, "price" double precision) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  new_order_id UUID;
BEGIN
  -- Check for valid quantity
  IF purchase_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than 0';
  END IF;

  -- Insert row into orders table
  INSERT INTO orders (customer_id, amount_paid, event_id) 
  VALUES (user_id, price, event_id)
  RETURNING id INTO new_order_id;

  -- Create line items
  INSERT INTO line_items (order_id, item_type, item_id, quantity, price) 
  VALUES (new_order_id, item_type, item_id, purchase_quantity, price / purchase_quantity);

  RETURN new_order_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating order: %', SQLERRM;
    RETURN NULL;
END;
$$;

ALTER FUNCTION "public"."create_order"("user_id" "uuid", "event_id" "uuid", "item_id" "uuid", "item_type" "public"."Checkout Ticket Types", "purchase_quantity" integer, "price" double precision) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."delete_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
    DELETE FROM auth.users WHERE id = OLD.id;
    RETURN OLD;
END;$$;

ALTER FUNCTION "public"."delete_profile"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_attendee_count"("event_id" "uuid") RETURNS bigint
    LANGUAGE "plpgsql"
    AS $$
declare
  attendee_count bigint;
begin
  select count(distinct attendee_id) into attendee_count
  from event_tickets et
  where et.event_id = get_attendee_count.event_id;

  return attendee_count;
end;
$$;

ALTER FUNCTION "public"."get_attendee_count"("event_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_attendee_data"("event_id" "uuid") RETURNS TABLE("attendee_id" "uuid", "first_name" "text", "last_name" "text", "email" "text", "avatar_url" "text", "phone" "text", "number_tickets_purchased" bigint, "date_of_last_purchase" timestamp with time zone, "number_tickets_scanned" bigint, "ticket_names" "text"[])
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.first_name,
    p.last_name,
    et.email,
    p.avatar_url,
    p.phone,
    COUNT(*)::BIGINT AS number_tickets_purchased,
    MAX(et.created_at) AS date_of_last_purchase,
    SUM(CASE WHEN et.valid THEN 0 ELSE 1 END)::BIGINT AS number_tickets_scanned,
    ARRAY_AGG(DISTINCT t.name) AS ticket_names
  FROM 
    event_tickets et
  JOIN 
    profiles p ON et.attendee_id = p.id
  JOIN 
    tickets t ON et.ticket_id = t.id
  WHERE 
    et.event_id = get_attendee_data.event_id
  GROUP BY 
    p.id, et.email
  ORDER BY 
    number_tickets_purchased DESC;
END;
$$;

ALTER FUNCTION "public"."get_attendee_data"("event_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."events" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "poster_url" "text" NOT NULL,
    "organizer_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "date" "date" NOT NULL,
    "address" "text" NOT NULL,
    "lng" double precision NOT NULL,
    "lat" double precision NOT NULL,
    "venue_name" "text" NOT NULL,
    "venue_map_url" "text",
    "featured" smallint DEFAULT '0'::smallint NOT NULL,
    "cleaned_name" "text" NOT NULL,
    "organizer_type" "text" DEFAULT 'profile'::"text" NOT NULL,
    "city" "text" DEFAULT ''::"text" NOT NULL,
    "state" "text" DEFAULT ''::"text" NOT NULL,
    "sales_status" "public"."Event Ticket Status" DEFAULT 'NO_SALE'::"public"."Event Ticket Status" NOT NULL,
    "vendor_exclusivity" "public"."Vendor Exclusivity" DEFAULT 'PUBLIC'::"public"."Vendor Exclusivity" NOT NULL,
    "min_date" "date" DEFAULT "now"() NOT NULL,
    "max_date" "date" DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."events" OWNER TO "postgres";

COMMENT ON COLUMN "public"."events"."cleaned_name" IS 'cleaned event name for urls';

COMMENT ON COLUMN "public"."events"."organizer_type" IS 'either profile or temporary_profile';

COMMENT ON COLUMN "public"."events"."sales_status" IS 'indicates whether event is selling tickets';

COMMENT ON COLUMN "public"."events"."vendor_exclusivity" IS 'indicates how exclusive the event is';

CREATE OR REPLACE FUNCTION "public"."get_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision) RETURNS SETOF "public"."events"
    LANGUAGE "plpgsql"
    AS $$BEGIN
    RETURN QUERY
    SELECT *
    FROM events e
    WHERE
        haversine_distance(user_lat, user_lon, e.lat, e.lng) <= radius;
END;$$;

ALTER FUNCTION "public"."get_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_tagged_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision, "tagid" "uuid") RETURNS SETOF "public"."events"
    LANGUAGE "plpgsql"
    AS $$BEGIN
    RETURN QUERY
    SELECT e.*
    FROM events e
    INNER JOIN event_tags et ON e.id = et.event_id
    WHERE
        haversine_distance(user_lat, user_lon, e.lat, e.lng) <= radius AND et.tag_id = tagId;
END;$$;

ALTER FUNCTION "public"."get_tagged_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision, "tagid" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_profile_transfer"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin 
  update events 
  set organizer_id = new.new_user_id,
      organizer_type = 'profile'
  where organizer_id = new.temp_profile_id;

  delete from profile_transfers
  where temp_profile_id = new.temp_profile_id;
  
  delete from temporary_profiles
  where id = new.temp_profile_id;

  delete from signup_invite_tokens
  where temp_profile_id = new.temp_profile_id;

  return new;
end;$$;

ALTER FUNCTION "public"."handle_profile_transfer"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."haversine_distance"("lat1" double precision, "lon1" double precision, "lat2" double precision, "lon2" double precision) RETURNS double precision
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    r DOUBLE PRECISION := 3959; -- Radius of the Earth in miles
    dlat DOUBLE PRECISION;
    dlon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    dlat := RADIANS(lat2 - lat1);
    dlon := RADIANS(lon2 - lon1);
    a := SIN(dlat / 2) * SIN(dlat / 2) + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * SIN(dlon / 2) * SIN(dlon / 2);
    c := 2 * ATAN2(SQRT(a), SQRT(1 - a));
    RETURN r * c;
END;
$$;

ALTER FUNCTION "public"."haversine_distance"("lat1" double precision, "lon1" double precision, "lat2" double precision, "lon2" double precision) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increment_promo"("promo_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE 
  new_num_used INT;
BEGIN
  -- Select the current num_used value into new_num_used
  SELECT num_used INTO new_num_used
  FROM public.event_codes
  WHERE id = promo_id;

  -- Increment the new_num_used variable
  new_num_used := new_num_used + 1;

  -- Update the num_used column in the event_codes table
  UPDATE public.event_codes
  SET num_used = new_num_used
  WHERE id = promo_id;

  return new_num_used;
END $$;

ALTER FUNCTION "public"."increment_promo"("promo_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."purchase_table"("table_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "amount_paid" double precision, "promo_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("order_id" integer, "event_name" "text", "organizer_id" "uuid", "event_date" timestamp with time zone, "event_address" "text", "event_description" "text", "event_cleaned_name" "text", "event_poster_url" "text", "table_section_name" "text", "table_price" double precision, "vendor_first_name" "text", "vendor_last_name" "text", "vendor_business_name" "text", "vendor_application_email" "text", "vendor_application_phone" "text", "vendor_table_quantity" integer, "vendor_inventory" "text", "vendor_vendors_at_table" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  table_quantity INT;
  table_price FLOAT;
  new_order_id INT;
  promo_num_used INT;
BEGIN
  IF purchase_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than 0';
  END IF;

  -- Select table quantity and price with given table_id
  SELECT quantity, price INTO table_quantity, table_price
  FROM tables
  WHERE id = table_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Table not found';
  END IF;

  -- Check to see if table has sufficient quantity
  IF table_quantity < purchase_quantity THEN
    RAISE EXCEPTION 'ERROR: insufficient table quantity';
  END IF;

  -- Update table quantity
  UPDATE tables 
  SET quantity = table_quantity - purchase_quantity 
  WHERE id = table_id;

  IF NOT FOUND THEN  
    RAISE EXCEPTION 'Error handling table quantity';
  END IF;

  -- Update event vendors to be PAID
  UPDATE event_vendors ev
  SET payment_status = 'PAID' 
  WHERE ev.event_id = purchase_table.event_id 
    AND ev.vendor_id = purchase_table.user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event vendor not found';
  END IF;

  -- Insert row into orders table
  INSERT INTO orders (customer_id, amount_paid, event_id, promo_code_id) 
  VALUES (user_id, amount_paid, event_id, promo_id)
  RETURNING id INTO new_order_id;

    -- Create line items
  INSERT INTO line_items (order_id, item_type, item_id, quantity, price) 
  VALUES (new_order_id, 'TABLE'::"Checkout Ticket Types", table_id, purchase_quantity, amount_paid / purchase_quantity);

  -- Check if promo was used. if it was update num used
  IF promo_id IS NOT NULL THEN  
    SELECT num_used INTO promo_num_used
    FROM event_codes
    WHERE id = promo_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Promo code not found';
    END IF;

    UPDATE event_codes
    SET num_used = promo_num_used + 1
    WHERE id = promo_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Error updating promo code usage';
    END IF;
  END IF;

  -- Return query with all necessary data
  RETURN QUERY
  SELECT 
    new_order_id AS order_id,
    e.name AS event_name,
    e.organizer_id,
    e.date::TIMESTAMP WITH TIME ZONE AS event_date,
    e.address AS event_address,
    e.description AS event_description,
    e.cleaned_name AS event_cleaned_name,
    e.poster_url as event_poster_url,
    t.section_name AS table_section_name,
    t.price AS table_price,
    p.first_name AS vendor_first_name,
    p.last_name AS vendor_last_name,
    p.business_name AS vendor_business_name,
    ev.application_email AS vendor_application_email,
    ev.application_phone AS vendor_application_phone,
    ev.table_quantity::INT AS vendor_table_quantity,
    ev.inventory AS vendor_inventory,
    ev.vendors_at_table::INT AS vendor_vendors_at_table
  FROM 
    event_vendors ev
    JOIN events e ON ev.event_id = e.id
    JOIN profiles p ON ev.vendor_id = p.id
    JOIN tables t ON t.id = purchase_table.table_id
  WHERE 
    ev.event_id = purchase_table.event_id 
    AND ev.vendor_id = purchase_table.user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No data found for the given event and vendor';
  END IF;
END;
$$;

ALTER FUNCTION "public"."purchase_table"("table_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "amount_paid" double precision, "promo_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."purchase_tickets"("ticket_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "email" "text", "amount_paid" double precision, "metadata" "json" DEFAULT NULL::"json", "promo_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("order_id" integer, "event_ticket_ids" "uuid"[], "event_name" "text", "event_date" timestamp with time zone, "event_address" "text", "event_description" "text", "event_cleaned_name" "text", "event_poster_url" "text", "event_organizer_id" "uuid", "ticket_name" "text", "ticket_price" double precision, "attendee_first_name" "text", "attendee_last_name" "text", "attendee_business_name" "text", "attendee_email" "text", "attendee_phone" "text", "organizer_id" "uuid", "organizer_phone" "text")
    LANGUAGE "plpgsql"
    AS $$DECLARE
  new_order_id INT;
  ticket_quantity INT;
  ticket_price FLOAT;
  promo_num_used INT;
  new_event_ticket_ids UUID[];
BEGIN 
  IF purchase_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be greater than 0';
  END IF;
  
  -- Select ticket quantity and price with given ticket_id
  SELECT quantity, price INTO ticket_quantity, ticket_price
  FROM tickets
  WHERE id = ticket_id;

  IF NOT FOUND THEN  -- Add check if ticket exists
    RAISE EXCEPTION 'Ticket not found';
  END IF;

  -- Check quantity of tickets
  IF ticket_quantity < purchase_quantity THEN
    RAISE EXCEPTION 'ERROR: insufficient ticket quantity';
  END IF;

  -- Update ticket quantity
  UPDATE tickets
  SET quantity = ticket_quantity - purchase_quantity 
  WHERE id = ticket_id;

  IF NOT FOUND THEN  -- Add check if update was successful
    RAISE EXCEPTION 'Error updating ticket quantity';
  END IF;

  -- Insert tickets into event_tickets
  WITH inserted_tickets AS (
    INSERT INTO event_tickets (attendee_id, event_id, ticket_id, email)
    SELECT user_id, event_id, ticket_id, email
    FROM generate_series(1, purchase_quantity)
    RETURNING id
  )
  SELECT array_agg(id) INTO new_event_ticket_ids FROM inserted_tickets;

  -- Create order
  INSERT INTO orders (customer_id, amount_paid, event_id, metadata, promo_code_id)
  VALUES (user_id, amount_paid, event_id, metadata, promo_id)
  RETURNING id INTO new_order_id;

  -- Insert line item
  INSERT INTO line_items (order_id, item_type, item_id, quantity, price)
  VALUES (new_order_id, 'TICKET'::"Checkout Ticket Types", ticket_id, purchase_quantity, amount_paid / purchase_quantity);

  -- Check if promo was used. if it was update num used
  IF promo_id IS NOT NULL THEN  
    SELECT num_used INTO promo_num_used
    FROM event_codes
    WHERE id = promo_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Promo code not found';
    END IF;

    UPDATE event_codes
    SET num_used = promo_num_used + 1
    WHERE id = promo_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Error updating promo code usage';
    END IF;
  END IF;

  -- Return query
  RETURN QUERY
  SELECT 
    new_order_id AS order_id,
    new_event_ticket_ids AS event_ticket_ids,
    e.name AS event_name,
    e.date::TIMESTAMP WITH TIME ZONE AS event_date,
    e.address AS event_address,
    e.description AS event_description,
    e.cleaned_name AS event_cleaned_name,
    e.poster_url AS event_poster_url,
    e.organizer_id AS event_organizer_id,
    t.name AS ticket_name,
    t.price AS ticket_price,
    p.first_name AS attendee_first_name,
    p.last_name AS attendee_last_name,
    p.business_name AS attendee_business_name,
    p.email AS attendee_email,
    p.phone AS attendee_phone,
    e.organizer_id,
    op.phone AS organizer_phone
  FROM 
    events e
    JOIN tickets t ON t.id = purchase_tickets.ticket_id
    JOIN profiles p ON p.id = purchase_tickets.user_id
    JOIN profiles op ON e.organizer_id = op.id
  WHERE 
    e.id = purchase_tickets.event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No data found for the purchased tickets';
  END IF;
END;$$;

ALTER FUNCTION "public"."purchase_tickets"("ticket_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "email" "text", "amount_paid" double precision, "metadata" "json", "promo_id" "uuid") OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."application_answers" (
    "id" "uuid" NOT NULL,
    "question_id" "uuid",
    "answer" "text",
    "question_type" "public"."Question Type" DEFAULT 'UNIQUE'::"public"."Question Type" NOT NULL,
    "vendor_id" "uuid" NOT NULL,
    "event_id" "uuid" NOT NULL
);

ALTER TABLE "public"."application_answers" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."application_standard_questions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "question_prompt" "text" NOT NULL
);

ALTER TABLE "public"."application_standard_questions" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."application_terms_and_conditions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "term" "text" NOT NULL
);

ALTER TABLE "public"."application_terms_and_conditions" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."application_vendor_information" (
    "event_id" "uuid" NOT NULL,
    "check_in_time" time without time zone NOT NULL,
    "check_in_location" "text" NOT NULL,
    "wifi_availability" boolean NOT NULL,
    "additional_information" "text",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."application_vendor_information" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL
);

ALTER TABLE "public"."categories" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."checkout_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ticket_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quantity" smallint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "ticket_type" "public"."Checkout Ticket Types" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'est'::"text") NOT NULL,
    "promo_id" "uuid",
    "price_type" "public"."Checkout Price Type" DEFAULT 'REGULAR'::"public"."Checkout Price Type" NOT NULL,
    "metadata" "json"
);

ALTER TABLE "public"."checkout_sessions" OWNER TO "postgres";

COMMENT ON COLUMN "public"."checkout_sessions"."promo_id" IS 'the promo code being applied if any';

CREATE TABLE IF NOT EXISTS "public"."event_categories" (
    "event_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."event_categories" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" DEFAULT ''::"text" NOT NULL,
    "discount" real DEFAULT '0'::real NOT NULL,
    "num_used" smallint DEFAULT '0'::smallint NOT NULL,
    "usage_limit" smallint,
    "status" "public"."Promo Code Status" DEFAULT 'ACTIVE'::"public"."Promo Code Status" NOT NULL,
    "type" "public"."Promo Code Type" DEFAULT 'DOLLAR'::"public"."Promo Code Type" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."event_codes" OWNER TO "postgres";

COMMENT ON TABLE "public"."event_codes" IS 'promo codes table';

CREATE TABLE IF NOT EXISTS "public"."event_dates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone,
    "date" "date" NOT NULL
);

ALTER TABLE "public"."event_dates" OWNER TO "postgres";

COMMENT ON TABLE "public"."event_dates" IS 'stores the dates and times of an event';

CREATE TABLE IF NOT EXISTS "public"."event_guests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "bio" "text" DEFAULT ''::"text" NOT NULL,
    "avatar_url" "text" NOT NULL,
    "event_id" "uuid" NOT NULL
);

ALTER TABLE "public"."event_guests" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_highlights" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "uploaded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "picture_url" "text" NOT NULL,
    "event_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."event_highlights" OWNER TO "postgres";

COMMENT ON TABLE "public"."event_highlights" IS 'past event highlights';

CREATE TABLE IF NOT EXISTS "public"."event_likes" (
    "event_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "liked_on" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."event_likes" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_tags" (
    "event_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tag_id" "uuid" NOT NULL
);

ALTER TABLE "public"."event_tags" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_tickets" (
    "attendee_id" "uuid" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "ticket_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "valid" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'est'::"text") NOT NULL,
    "email" "text"
);

ALTER TABLE "public"."event_tickets" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_tickets_dates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_ticket_id" "uuid" NOT NULL,
    "event_dates_id" "uuid" NOT NULL,
    "valid" boolean DEFAULT true NOT NULL,
    "checked_in_at" timestamp with time zone
);

ALTER TABLE "public"."event_tickets_dates" OWNER TO "postgres";

COMMENT ON TABLE "public"."event_tickets_dates" IS 'stores check-in and validity for each tickets valid date';

CREATE TABLE IF NOT EXISTS "public"."event_vendor_tags" (
    "event_id" "uuid" NOT NULL,
    "vendor_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL
);

ALTER TABLE "public"."event_vendor_tags" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_vendors" (
    "event_id" "uuid" NOT NULL,
    "vendor_id" "uuid" NOT NULL,
    "application_status" "public"."Application Status" DEFAULT 'PENDING'::"public"."Application Status" NOT NULL,
    "payment_status" "public"."Payment Status" DEFAULT 'UNPAID'::"public"."Payment Status" NOT NULL,
    "table_id" "uuid" NOT NULL,
    "table_quantity" smallint NOT NULL,
    "vendors_at_table" smallint NOT NULL,
    "inventory" "text" NOT NULL,
    "comments" "text",
    "application_phone" "text" NOT NULL,
    "application_email" "text" NOT NULL,
    "assignment" smallint,
    "checked_in" boolean DEFAULT false NOT NULL,
    "notified_of_assignment" boolean DEFAULT false NOT NULL
);

ALTER TABLE "public"."event_vendors" OWNER TO "postgres";

COMMENT ON COLUMN "public"."event_vendors"."assignment" IS 'vendor table assignment';

COMMENT ON COLUMN "public"."event_vendors"."notified_of_assignment" IS 'true if they''ve been notified of their recent assignment';

CREATE TABLE IF NOT EXISTS "public"."event_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visited_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "visitor_id" "uuid" DEFAULT "gen_random_uuid"(),
    "event_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."event_views" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."line_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quantity" integer NOT NULL,
    "price" double precision NOT NULL,
    "item_id" "uuid" NOT NULL,
    "item_type" "public"."Checkout Ticket Types" NOT NULL,
    "order_id" bigint NOT NULL
);

ALTER TABLE "public"."line_items" OWNER TO "postgres";

COMMENT ON TABLE "public"."line_items" IS 'universal line items table to store both tables and tickets (and any other types of items in the future)';

CREATE TABLE IF NOT EXISTS "public"."links" (
    "user_id" "uuid" NOT NULL,
    "username" "text" NOT NULL,
    "application" "text" NOT NULL,
    "id" bigint NOT NULL,
    "type" "text" DEFAULT 'social'::"text" NOT NULL
);

ALTER TABLE "public"."links" OWNER TO "postgres";

ALTER TABLE "public"."links" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."links_id-pk_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."orders" (
    "customer_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "amount_paid" double precision NOT NULL,
    "event_id" "uuid" NOT NULL,
    "id" bigint NOT NULL,
    "metadata" "json",
    "promo_code_id" "uuid"
);

ALTER TABLE "public"."orders" OWNER TO "postgres";

ALTER TABLE "public"."orders" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."orders_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."portfolio_pictures" (
    "uploaded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "picture_url" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."portfolio_pictures" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."profile_transfers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "temp_profile_id" "uuid" DEFAULT "gen_random_uuid"(),
    "new_user_id" "uuid" DEFAULT "gen_random_uuid"()
);

ALTER TABLE "public"."profile_transfers" OWNER TO "postgres";

COMMENT ON TABLE "public"."profile_transfers" IS 'intermediary table that trigger listens to to handle profile transfers';

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text",
    "first_name" "text" NOT NULL,
    "last_name" "text" NOT NULL,
    "bio" "text",
    "avatar_url" "text" DEFAULT 'default_avatar'::"text" NOT NULL,
    "username" "text" NOT NULL,
    "discriminator" smallint,
    "role" "text" DEFAULT 'user'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "business_name" "text",
    "phone" "text"
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

COMMENT ON TABLE "public"."profiles" IS 'Profile data for each user.';

COMMENT ON COLUMN "public"."profiles"."id" IS 'References the internal Supabase Auth user.';

COMMENT ON COLUMN "public"."profiles"."discriminator" IS 'key for username';

CREATE TABLE IF NOT EXISTS "public"."signup_invite_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "token" "uuid" NOT NULL,
    "temp_profile_id" "uuid" NOT NULL
);

ALTER TABLE "public"."signup_invite_tokens" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."tables" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "price" double precision NOT NULL,
    "quantity" integer NOT NULL,
    "section_name" "text" NOT NULL,
    "table_provided" boolean DEFAULT false NOT NULL,
    "space_allocated" integer DEFAULT 8 NOT NULL,
    "number_vendors_allowed" integer DEFAULT 2 NOT NULL,
    "additional_information" "text",
    "total_tables" integer DEFAULT 0 NOT NULL
);

ALTER TABLE "public"."tables" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."tags" (
    "name" "text" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."tags" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."temporary_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "username" "text" NOT NULL,
    "avatar_url" "text" DEFAULT 'default_avatar.jpeg'::"text" NOT NULL,
    "instagram" "text",
    "business_name" "text" NOT NULL
);

ALTER TABLE "public"."temporary_profiles" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."temporary_profiles_vendors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "avatar_url" "text" NOT NULL,
    "business_name" "text" NOT NULL,
    "email" "text",
    "instagram" "text"
);

ALTER TABLE "public"."temporary_profiles_vendors" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."temporary_vendors" (
    "event_id" "uuid" NOT NULL,
    "vendor_id" "uuid" NOT NULL,
    "assignment" smallint,
    "tag_id" "uuid"
);

ALTER TABLE "public"."temporary_vendors" OWNER TO "postgres";

COMMENT ON COLUMN "public"."temporary_vendors"."assignment" IS 'vendor table assignment';

CREATE TABLE IF NOT EXISTS "public"."ticket_dates" (
    "ticket_id" "uuid" NOT NULL,
    "event_date_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."ticket_dates" OWNER TO "postgres";

COMMENT ON TABLE "public"."ticket_dates" IS 'stores the dates a ticket is valid on';

CREATE TABLE IF NOT EXISTS "public"."tickets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "price" double precision NOT NULL,
    "quantity" bigint NOT NULL,
    "name" "text" DEFAULT 'GA'::"text" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "total_tickets" bigint DEFAULT '0'::bigint NOT NULL,
    "description" "text"
);

ALTER TABLE "public"."tickets" OWNER TO "postgres";

COMMENT ON COLUMN "public"."tickets"."total_tickets" IS 'Total number of tickets available for an event';

CREATE TABLE IF NOT EXISTS "public"."vendor_invite_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token" "uuid" DEFAULT "gen_random_uuid"(),
    "expires_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."vendor_invite_tokens" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."vendor_transactions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "vendor_id" "uuid",
    "item_name" "text",
    "amount" double precision,
    "method" "text" NOT NULL
);

ALTER TABLE "public"."vendor_transactions" OWNER TO "postgres";

ALTER TABLE "public"."vendor_transactions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vendor_transactions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY "public"."application_answers"
    ADD CONSTRAINT "application_answers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."application_standard_questions"
    ADD CONSTRAINT "application_standard_questions_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."application_terms_and_conditions"
    ADD CONSTRAINT "application_terms_and_conditions_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."application_vendor_information"
    ADD CONSTRAINT "application_vendor_information_event_id_key" UNIQUE ("event_id");

ALTER TABLE ONLY "public"."application_vendor_information"
    ADD CONSTRAINT "application_vendor_information_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."checkout_sessions"
    ADD CONSTRAINT "checkout_sessions_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_categories"
    ADD CONSTRAINT "event_categories_pkey" PRIMARY KEY ("event_id", "category_id");

ALTER TABLE ONLY "public"."event_codes"
    ADD CONSTRAINT "event_codes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_dates"
    ADD CONSTRAINT "event_dates_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_guests"
    ADD CONSTRAINT "event_guests_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_highlights"
    ADD CONSTRAINT "event_highlights_picture_url_key" UNIQUE ("picture_url");

ALTER TABLE ONLY "public"."event_highlights"
    ADD CONSTRAINT "event_highlights_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_likes"
    ADD CONSTRAINT "event_likes_pkey" PRIMARY KEY ("event_id", "user_id");

ALTER TABLE ONLY "public"."event_views"
    ADD CONSTRAINT "event_page_views_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "event_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_tags"
    ADD CONSTRAINT "event_tags_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_tickets_dates"
    ADD CONSTRAINT "event_tickets_dates_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_tickets"
    ADD CONSTRAINT "event_tickets_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_vendor_tags"
    ADD CONSTRAINT "event_vendor_tags_pkey" PRIMARY KEY ("event_id", "vendor_id", "tag_id");

ALTER TABLE ONLY "public"."event_vendors"
    ADD CONSTRAINT "event_vendors_pkey" PRIMARY KEY ("vendor_id", "event_id");

ALTER TABLE ONLY "public"."line_items"
    ADD CONSTRAINT "line_items_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."links"
    ADD CONSTRAINT "links_id-pk_key" UNIQUE ("id");

ALTER TABLE ONLY "public"."links"
    ADD CONSTRAINT "links_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."portfolio_pictures"
    ADD CONSTRAINT "portfolio_pictures_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profile_transfers"
    ADD CONSTRAINT "profile_transfers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_phone_key" UNIQUE ("phone");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");

ALTER TABLE ONLY "public"."signup_invite_tokens"
    ADD CONSTRAINT "signup_invite_tokens_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tables"
    ADD CONSTRAINT "tables_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_name_key" UNIQUE ("name");

ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."temporary_profiles"
    ADD CONSTRAINT "temporary_profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."temporary_profiles_vendors"
    ADD CONSTRAINT "temporary_profiles_vendors_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."temporary_vendors"
    ADD CONSTRAINT "temporary_vendors_pkey" PRIMARY KEY ("event_id", "vendor_id");

ALTER TABLE ONLY "public"."ticket_dates"
    ADD CONSTRAINT "ticket_dates_id_key" UNIQUE ("id");

ALTER TABLE ONLY "public"."ticket_dates"
    ADD CONSTRAINT "ticket_dates_pkey" PRIMARY KEY ("ticket_id", "event_date_id");

ALTER TABLE ONLY "public"."tickets"
    ADD CONSTRAINT "tickets_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."vendor_invite_tokens"
    ADD CONSTRAINT "vendor_invite_tokens_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."vendor_invite_tokens"
    ADD CONSTRAINT "vendor_invite_tokens_token_key" UNIQUE ("token");

ALTER TABLE ONLY "public"."vendor_transactions"
    ADD CONSTRAINT "vendor_transactions_pkey" PRIMARY KEY ("id");

CREATE OR REPLACE TRIGGER "handle_delete_profile" AFTER DELETE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."delete_profile"();

CREATE OR REPLACE TRIGGER "handle_transfer_of_profile" AFTER INSERT ON "public"."profile_transfers" FOR EACH ROW EXECUTE FUNCTION "public"."handle_profile_transfer"();

ALTER TABLE ONLY "public"."application_terms_and_conditions"
    ADD CONSTRAINT "application_terms_and_conditions_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."application_vendor_information"
    ADD CONSTRAINT "application_vendor_information_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."checkout_sessions"
    ADD CONSTRAINT "checkout_sessions_promo_id_fkey" FOREIGN KEY ("promo_id") REFERENCES "public"."event_codes"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_categories"
    ADD CONSTRAINT "event_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");

ALTER TABLE ONLY "public"."event_categories"
    ADD CONSTRAINT "event_categories_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id");

ALTER TABLE ONLY "public"."event_dates"
    ADD CONSTRAINT "event_dates_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_guests"
    ADD CONSTRAINT "event_guests_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_highlights"
    ADD CONSTRAINT "event_highlights_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_likes"
    ADD CONSTRAINT "event_likes_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_likes"
    ADD CONSTRAINT "event_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_views"
    ADD CONSTRAINT "event_page_views_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_views"
    ADD CONSTRAINT "event_page_views_visitor_id_fkey" FOREIGN KEY ("visitor_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY "public"."event_tags"
    ADD CONSTRAINT "event_tags_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_tags"
    ADD CONSTRAINT "event_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_tickets"
    ADD CONSTRAINT "event_tickets_attendee_id_fkey" FOREIGN KEY ("attendee_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_tickets_dates"
    ADD CONSTRAINT "event_tickets_dates_event_dates_id_fkey" FOREIGN KEY ("event_dates_id") REFERENCES "public"."event_dates"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_tickets_dates"
    ADD CONSTRAINT "event_tickets_dates_event_ticket_id_fkey" FOREIGN KEY ("event_ticket_id") REFERENCES "public"."event_tickets"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_tickets"
    ADD CONSTRAINT "event_tickets_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_tickets"
    ADD CONSTRAINT "event_tickets_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "public"."tickets"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_vendor_tags"
    ADD CONSTRAINT "event_vendor_tags_event_id_vendor_id_fkey" FOREIGN KEY ("event_id", "vendor_id") REFERENCES "public"."event_vendors"("event_id", "vendor_id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_vendor_tags"
    ADD CONSTRAINT "event_vendor_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id");

ALTER TABLE ONLY "public"."event_vendors"
    ADD CONSTRAINT "event_vendors_table_id_fkey" FOREIGN KEY ("table_id") REFERENCES "public"."tables"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_vendors"
    ADD CONSTRAINT "event_vendors_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."line_items"
    ADD CONSTRAINT "line_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."links"
    ADD CONSTRAINT "links_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_promo_code_id_fkey" FOREIGN KEY ("promo_code_id") REFERENCES "public"."event_codes"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."portfolio_pictures"
    ADD CONSTRAINT "portfolio_pictures_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."checkout_sessions"
    ADD CONSTRAINT "public_checkout_sessions_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."checkout_sessions"
    ADD CONSTRAINT "public_checkout_sessions_user_Id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_codes"
    ADD CONSTRAINT "public_event_codes_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_vendors"
    ADD CONSTRAINT "public_event_vendors_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."vendor_transactions"
    ADD CONSTRAINT "public_vendor_transactions_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."tables"
    ADD CONSTRAINT "tables_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."temporary_profiles_vendors"
    ADD CONSTRAINT "temporary_profiles_vendors_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."temporary_vendors"
    ADD CONSTRAINT "temporary_vendors_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."temporary_vendors"
    ADD CONSTRAINT "temporary_vendors_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."temporary_vendors"
    ADD CONSTRAINT "temporary_vendors_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."temporary_profiles_vendors"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ticket_dates"
    ADD CONSTRAINT "ticket_dates_event_date_id_fkey" FOREIGN KEY ("event_date_id") REFERENCES "public"."event_dates"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ticket_dates"
    ADD CONSTRAINT "ticket_dates_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "public"."tickets"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."tickets"
    ADD CONSTRAINT "tickets_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE POLICY "Allow delete to auth users" ON "public"."temporary_vendors" FOR DELETE USING (true);

CREATE POLICY "Enable delete for authenticated users only" ON "public"."event_guests" FOR DELETE TO "authenticated" USING (true);

CREATE POLICY "Enable delete for authenticated users only" ON "public"."event_tags" FOR DELETE TO "authenticated" USING (true);

CREATE POLICY "Enable delete for event organizer or admin" ON "public"."event_highlights" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM "public"."events"
  WHERE (("events"."id" = "event_highlights"."event_id") AND ("events"."organizer_id" = "auth"."uid"())))) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text"))))));

CREATE POLICY "Enable delete for users based on organizer_id" ON "public"."events" FOR DELETE USING (("auth"."uid"() = "organizer_id"));

CREATE POLICY "Enable delete for users based on user_id" ON "public"."event_likes" FOR DELETE USING (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable delete for users based on user_id" ON "public"."portfolio_pictures" FOR DELETE USING (("auth"."uid"() = "user_id"));

CREATE POLICY "Enable insert access for all users" ON "public"."event_views" FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert access to anyone" ON "public"."profiles" FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert for all users" ON "public"."line_items" FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert for all users" ON "public"."orders" FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert for all users" ON "public"."profile_transfers" FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."checkout_sessions" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_guests" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_highlights" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_likes" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_tags" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_tickets" FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_vendor_tags" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."event_vendors" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."events" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."portfolio_pictures" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."signup_invite_tokens" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."temporary_profiles" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."temporary_profiles_vendors" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."temporary_vendors" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."tickets" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."vendor_invite_tokens" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON "public"."categories" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."checkout_sessions" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_categories" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_dates" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_guests" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_highlights" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_likes" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_tags" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_vendor_tags" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."event_vendors" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."events" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."line_items" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."orders" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."portfolio_pictures" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."profile_transfers" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."profiles" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."signup_invite_tokens" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."tags" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."temporary_profiles" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."temporary_vendors" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."tickets" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."vendor_invite_tokens" FOR SELECT USING (true);

CREATE POLICY "Enable read access for creators of temp vendors" ON "public"."temporary_profiles_vendors" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "creator_id"));

CREATE POLICY "Enable read access for specific users" ON "public"."event_tickets" FOR SELECT USING (true);

CREATE POLICY "Enable select for authenticated users only" ON "public"."event_views" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Enable update for users" ON "public"."tables" FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Enable update for users" ON "public"."tickets" FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Enable update for users based on email" ON "public"."event_vendors" FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Enable update for users based on id" ON "public"."checkout_sessions" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));

CREATE POLICY "Enable update for users based on id or admin" ON "public"."profiles" FOR UPDATE USING ((("auth"."uid"() = "id") OR (( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = 'admin'::"text"))) WITH CHECK ((("auth"."uid"() = "id") OR (( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = 'admin'::"text")));

CREATE POLICY "Enable update for users based on uid or if user is admin" ON "public"."events" FOR UPDATE USING ((("auth"."uid"() = "organizer_id") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text"))) WITH CHECK ((("auth"."uid"() = "organizer_id") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text")));

CREATE POLICY "Update" ON "public"."temporary_vendors" FOR UPDATE TO "authenticated" USING (true);

CREATE POLICY "allow all users read access" ON "public"."links" FOR SELECT USING (true);

CREATE POLICY "allow authenticated to insert" ON "public"."vendor_transactions" FOR INSERT WITH CHECK (true);

CREATE POLICY "allow delete to auth users" ON "public"."links" FOR DELETE TO "authenticated" USING (true);

CREATE POLICY "allow public updates" ON "public"."event_codes" FOR UPDATE USING (true);

ALTER TABLE "public"."application_answers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."application_standard_questions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."application_terms_and_conditions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."application_vendor_information" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."checkout_sessions" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "delete auth" ON "public"."tables" FOR DELETE TO "authenticated" USING (true);

CREATE POLICY "delete auth users" ON "public"."application_terms_and_conditions" FOR DELETE TO "authenticated" USING (true);

CREATE POLICY "delete only auth users" ON "public"."vendor_transactions" FOR DELETE TO "authenticated" USING (true);

CREATE POLICY "enable insert for authenticated users" ON "public"."event_codes" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "enable select for all sers" ON "public"."event_codes" FOR SELECT USING (true);

ALTER TABLE "public"."event_categories" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_codes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_dates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_guests" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_highlights" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_likes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_tags" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_tickets_dates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_vendor_tags" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_vendors" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."event_views" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "insert access to auth users" ON "public"."links" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "insert auth" ON "public"."application_vendor_information" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "insert auth" ON "public"."tables" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "insert auth users" ON "public"."application_terms_and_conditions" FOR INSERT TO "authenticated" WITH CHECK (true);

ALTER TABLE "public"."line_items" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."links" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."portfolio_pictures" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profile_transfers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read only auth users" ON "public"."vendor_transactions" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "read public" ON "public"."tables" FOR SELECT USING (true);

CREATE POLICY "select" ON "public"."application_terms_and_conditions" FOR SELECT USING (true);

CREATE POLICY "select public" ON "public"."application_vendor_information" FOR SELECT USING (true);

ALTER TABLE "public"."signup_invite_tokens" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tables" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."temporary_profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."temporary_profiles_vendors" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."temporary_vendors" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ticket_dates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tickets" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user can update theirs or admin can" ON "public"."links" FOR UPDATE USING ((("auth"."uid"() = "user_id") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text"))) WITH CHECK ((("auth"."uid"() = "user_id") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text")));

ALTER TABLE "public"."vendor_invite_tokens" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."vendor_transactions" ENABLE ROW LEVEL SECURITY;

ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."create_order"("user_id" "uuid", "event_id" "uuid", "item_id" "uuid", "item_type" "public"."Checkout Ticket Types", "purchase_quantity" integer, "price" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."create_order"("user_id" "uuid", "event_id" "uuid", "item_id" "uuid", "item_type" "public"."Checkout Ticket Types", "purchase_quantity" integer, "price" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_order"("user_id" "uuid", "event_id" "uuid", "item_id" "uuid", "item_type" "public"."Checkout Ticket Types", "purchase_quantity" integer, "price" double precision) TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_profile"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_attendee_count"("event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_attendee_count"("event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_attendee_count"("event_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_attendee_data"("event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_attendee_data"("event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_attendee_data"("event_id" "uuid") TO "service_role";

GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";

GRANT ALL ON FUNCTION "public"."get_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."get_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_tagged_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision, "tagid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_tagged_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision, "tagid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_tagged_nearby_events"("user_lat" double precision, "user_lon" double precision, "radius" double precision, "tagid" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_profile_transfer"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_profile_transfer"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_profile_transfer"() TO "service_role";

GRANT ALL ON FUNCTION "public"."haversine_distance"("lat1" double precision, "lon1" double precision, "lat2" double precision, "lon2" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."haversine_distance"("lat1" double precision, "lon1" double precision, "lat2" double precision, "lon2" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."haversine_distance"("lat1" double precision, "lon1" double precision, "lat2" double precision, "lon2" double precision) TO "service_role";

GRANT ALL ON FUNCTION "public"."increment_promo"("promo_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."increment_promo"("promo_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_promo"("promo_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."purchase_table"("table_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "amount_paid" double precision, "promo_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."purchase_table"("table_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "amount_paid" double precision, "promo_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."purchase_table"("table_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "amount_paid" double precision, "promo_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."purchase_tickets"("ticket_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "email" "text", "amount_paid" double precision, "metadata" "json", "promo_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."purchase_tickets"("ticket_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "email" "text", "amount_paid" double precision, "metadata" "json", "promo_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."purchase_tickets"("ticket_id" "uuid", "event_id" "uuid", "user_id" "uuid", "purchase_quantity" integer, "email" "text", "amount_paid" double precision, "metadata" "json", "promo_id" "uuid") TO "service_role";

GRANT ALL ON TABLE "public"."application_answers" TO "anon";
GRANT ALL ON TABLE "public"."application_answers" TO "authenticated";
GRANT ALL ON TABLE "public"."application_answers" TO "service_role";

GRANT ALL ON TABLE "public"."application_standard_questions" TO "anon";
GRANT ALL ON TABLE "public"."application_standard_questions" TO "authenticated";
GRANT ALL ON TABLE "public"."application_standard_questions" TO "service_role";

GRANT ALL ON TABLE "public"."application_terms_and_conditions" TO "anon";
GRANT ALL ON TABLE "public"."application_terms_and_conditions" TO "authenticated";
GRANT ALL ON TABLE "public"."application_terms_and_conditions" TO "service_role";

GRANT ALL ON TABLE "public"."application_vendor_information" TO "anon";
GRANT ALL ON TABLE "public"."application_vendor_information" TO "authenticated";
GRANT ALL ON TABLE "public"."application_vendor_information" TO "service_role";

GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";

GRANT ALL ON TABLE "public"."checkout_sessions" TO "anon";
GRANT ALL ON TABLE "public"."checkout_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."checkout_sessions" TO "service_role";

GRANT ALL ON TABLE "public"."event_categories" TO "anon";
GRANT ALL ON TABLE "public"."event_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."event_categories" TO "service_role";

GRANT ALL ON TABLE "public"."event_codes" TO "anon";
GRANT ALL ON TABLE "public"."event_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."event_codes" TO "service_role";

GRANT ALL ON TABLE "public"."event_dates" TO "anon";
GRANT ALL ON TABLE "public"."event_dates" TO "authenticated";
GRANT ALL ON TABLE "public"."event_dates" TO "service_role";

GRANT ALL ON TABLE "public"."event_guests" TO "anon";
GRANT ALL ON TABLE "public"."event_guests" TO "authenticated";
GRANT ALL ON TABLE "public"."event_guests" TO "service_role";

GRANT ALL ON TABLE "public"."event_highlights" TO "anon";
GRANT ALL ON TABLE "public"."event_highlights" TO "authenticated";
GRANT ALL ON TABLE "public"."event_highlights" TO "service_role";

GRANT ALL ON TABLE "public"."event_likes" TO "anon";
GRANT ALL ON TABLE "public"."event_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."event_likes" TO "service_role";

GRANT ALL ON TABLE "public"."event_tags" TO "anon";
GRANT ALL ON TABLE "public"."event_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."event_tags" TO "service_role";

GRANT ALL ON TABLE "public"."event_tickets" TO "anon";
GRANT ALL ON TABLE "public"."event_tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."event_tickets" TO "service_role";

GRANT ALL ON TABLE "public"."event_tickets_dates" TO "anon";
GRANT ALL ON TABLE "public"."event_tickets_dates" TO "authenticated";
GRANT ALL ON TABLE "public"."event_tickets_dates" TO "service_role";

GRANT ALL ON TABLE "public"."event_vendor_tags" TO "anon";
GRANT ALL ON TABLE "public"."event_vendor_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."event_vendor_tags" TO "service_role";

GRANT ALL ON TABLE "public"."event_vendors" TO "anon";
GRANT ALL ON TABLE "public"."event_vendors" TO "authenticated";
GRANT ALL ON TABLE "public"."event_vendors" TO "service_role";

GRANT ALL ON TABLE "public"."event_views" TO "anon";
GRANT ALL ON TABLE "public"."event_views" TO "authenticated";
GRANT ALL ON TABLE "public"."event_views" TO "service_role";

GRANT ALL ON TABLE "public"."line_items" TO "anon";
GRANT ALL ON TABLE "public"."line_items" TO "authenticated";
GRANT ALL ON TABLE "public"."line_items" TO "service_role";

GRANT ALL ON TABLE "public"."links" TO "anon";
GRANT ALL ON TABLE "public"."links" TO "authenticated";
GRANT ALL ON TABLE "public"."links" TO "service_role";

GRANT ALL ON SEQUENCE "public"."links_id-pk_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."links_id-pk_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."links_id-pk_seq" TO "service_role";

GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";

GRANT ALL ON SEQUENCE "public"."orders_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."orders_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."orders_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."portfolio_pictures" TO "anon";
GRANT ALL ON TABLE "public"."portfolio_pictures" TO "authenticated";
GRANT ALL ON TABLE "public"."portfolio_pictures" TO "service_role";

GRANT ALL ON TABLE "public"."profile_transfers" TO "anon";
GRANT ALL ON TABLE "public"."profile_transfers" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_transfers" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."signup_invite_tokens" TO "anon";
GRANT ALL ON TABLE "public"."signup_invite_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."signup_invite_tokens" TO "service_role";

GRANT ALL ON TABLE "public"."tables" TO "anon";
GRANT ALL ON TABLE "public"."tables" TO "authenticated";
GRANT ALL ON TABLE "public"."tables" TO "service_role";

GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";

GRANT ALL ON TABLE "public"."temporary_profiles" TO "anon";
GRANT ALL ON TABLE "public"."temporary_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."temporary_profiles" TO "service_role";

GRANT ALL ON TABLE "public"."temporary_profiles_vendors" TO "anon";
GRANT ALL ON TABLE "public"."temporary_profiles_vendors" TO "authenticated";
GRANT ALL ON TABLE "public"."temporary_profiles_vendors" TO "service_role";

GRANT ALL ON TABLE "public"."temporary_vendors" TO "anon";
GRANT ALL ON TABLE "public"."temporary_vendors" TO "authenticated";
GRANT ALL ON TABLE "public"."temporary_vendors" TO "service_role";

GRANT ALL ON TABLE "public"."ticket_dates" TO "anon";
GRANT ALL ON TABLE "public"."ticket_dates" TO "authenticated";
GRANT ALL ON TABLE "public"."ticket_dates" TO "service_role";

GRANT ALL ON TABLE "public"."tickets" TO "anon";
GRANT ALL ON TABLE "public"."tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."tickets" TO "service_role";

GRANT ALL ON TABLE "public"."vendor_invite_tokens" TO "anon";
GRANT ALL ON TABLE "public"."vendor_invite_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."vendor_invite_tokens" TO "service_role";

GRANT ALL ON TABLE "public"."vendor_transactions" TO "anon";
GRANT ALL ON TABLE "public"."vendor_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."vendor_transactions" TO "service_role";

GRANT ALL ON SEQUENCE "public"."vendor_transactions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vendor_transactions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vendor_transactions_id_seq" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
