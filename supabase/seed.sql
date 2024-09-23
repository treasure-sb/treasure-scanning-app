DROP EXTENSION IF EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1 (Ubuntu 15.1-1.pgdg20.04+1)
-- Dumped by pg_dump version 15.5 (Ubuntu 15.5-1.pgdg20.04+1)

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

--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."buckets" ("id", "name", "owner", "created_at", "updated_at", "public", "avif_autodetection", "file_size_limit", "allowed_mime_types", "owner_id") VALUES
	('posters', 'posters', NULL, '2023-11-18 21:49:53.352148+00', '2023-11-18 21:49:53.352148+00', true, false, NULL, NULL, NULL),
	('avatars', 'avatars', NULL, '2023-11-21 20:36:07.935236+00', '2023-11-21 20:36:07.935236+00', true, false, NULL, NULL, NULL),
	('venue_maps', 'venue_maps', NULL, '2023-11-25 02:14:40.495308+00', '2023-11-25 02:14:40.495308+00', true, false, NULL, NULL, NULL),
	('portfolios', 'portfolios', NULL, '2023-12-19 23:04:50.624353+00', '2023-12-19 23:04:50.624353+00', true, false, NULL, NULL, NULL),
	('event_highlights', 'event_highlights', NULL, '2024-05-05 04:42:15.390642+00', '2024-05-05 04:42:15.390642+00', true, false, NULL, NULL, NULL),
	('guest_images', 'guest_images', NULL, '2024-05-06 04:10:35.812723+00', '2024-05-06 04:10:35.812723+00', true, false, NULL, NULL, NULL);

-- create test users
INSERT INTO
    auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) (
        select
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            'user' || (ROW_NUMBER() OVER ()) || '@example.com',
            md5('password123' || gen_random_uuid()::text),
            current_timestamp,
            current_timestamp,
            current_timestamp,
            '{"provider":"email","providers":["email"]}',
            '{}',
            current_timestamp,
            current_timestamp,
            '',
            '',
            '',
            ''
        FROM
            generate_series(1, 100)
    );

-- test user email identities
INSERT INTO
    auth.identities (
        id,
        user_id,
        provider_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) (
        select
            gen_random_uuid(),
            id,
            id,
            format('{"sub":"%s","email":"%s"}', id :: text, email) :: jsonb,
            'email',
            current_timestamp,
            current_timestamp,
            current_timestamp
        from
            auth.users
    );

-- create users in public.profiles table (user1@example.com is admin)
WITH names AS (
    SELECT ARRAY[
        'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles',
        'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Margaret', 'Susan', 'Dorothy', 'Lisa', 'Karen', 'George', 
				'Edward', 'Daniel', 'Brian', 'Ronald', 'Anthony', 'Kevin', 'Jason', 'Matthew', 'Gary', 'Timothy', 'Jose', 'Larry', 'Jeffrey', 
				'Frank', 'Scott', 'Eric', 'Stephen', 'Andrew', 'Raymond', 'Gregory', 'Joshua', 'Jerry', 'Dennis', 'Walter', 'Patrick', 'Peter'
    ] AS first_names,
    ARRAY[
        'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
        'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson'
    ] AS last_names
),
random_names AS (
    SELECT 
        id,
        email,
        first_names[floor(random() * array_length(first_names, 1) + 1)] AS random_first_name,
        last_names[floor(random() * array_length(last_names, 1) + 1)] AS random_last_name
    FROM auth.users, names
)
INSERT INTO
    public.profiles (
        id,
        username,
        avatar_url,
        created_at,
        first_name,    
        last_name,
        business_name,
        email,
        role
    ) (
        SELECT
            rn.id,
            lower(rn.random_first_name || '.' || rn.random_last_name) || (ROW_NUMBER() OVER ()),
            'avatar' || (floor(random() * 10 + 1)::int)::text || '.jpg',
            current_timestamp,
            rn.random_first_name,
            rn.random_last_name,
            rn.random_first_name || '''s Business',
            rn.email,
            CASE 
                WHEN ROW_NUMBER() OVER () = 1 THEN 'admin'
                ELSE 'user'
            END as role
        FROM random_names rn
    );

-- create tags
INSERT INTO public.tags(id, name) VALUES 
	(gen_random_uuid(), 'One-Piece'), 
	(gen_random_uuid(), 'TCG'),
	(gen_random_uuid(), 'Sports'),
	(gen_random_uuid(), 'Non-Sports'),
	(gen_random_uuid(), 'Anime'),
	(gen_random_uuid(), 'Collectibles'),
	(gen_random_uuid(), 'Toys'),
	(gen_random_uuid(), 'Pokemon'),
	(gen_random_uuid(), 'Comics'),
	(gen_random_uuid(), 'Memorabilia'),
	(gen_random_uuid(), 'Plushies'),
	(gen_random_uuid(), 'Autographs'),
	(gen_random_uuid(), 'Cosplay');

ALTER TABLE public.orders
ALTER COLUMN id RESTART WITH 100000;

-- create events
DO $$
DECLARE
    host_profile_ids UUID[];
    profile_ids UUID[];
    tag_ids UUID[];
    random_profile_id UUID;
    e_event_id UUID;
    e_table_id UUID;
    i INTEGER;
    j INTEGER;
    event_lat FLOAT := 40.7128;  -- Latitude for New York City
    event_lng FLOAT := -74.0060; -- Longitude for New York City
    days_to_add INTEGER;
    future_date DATE;
    num_tags INTEGER;
    random_tag_id UUID;
    total_days INTEGER := 180;
BEGIN
    -- Fetch 5 host profile IDs
    SELECT ARRAY(SELECT id FROM public.profiles order by random() limit 5) INTO host_profile_ids;

    -- Fetch all profile IDs
    SELECT ARRAY(SELECT id FROM public.profiles) INTO profile_ids;
    
    -- Fetch all tag IDs
    SELECT ARRAY(SELECT id FROM public.tags) INTO tag_ids;

    -- Create 20 events
    FOR i IN 1..10 LOOP
        -- Select a random profile ID
        random_profile_id := host_profile_ids[floor(random() * array_length(host_profile_ids, 1) + 1)];

        -- Generate a random future weekend date within the next 6 months
        days_to_add := (i - 1) * (total_days / 9);
        future_date := current_date + (days_to_add || ' days')::interval;
        
        -- Adjust to the next Saturday if it's not already a weekend
        WHILE EXTRACT(DOW FROM future_date) != 6 LOOP
            future_date := future_date + interval '1 day';
        END LOOP;

        -- Insert event
        INSERT INTO public.events (
            id,
            created_at,
            name,
            description,
            start_time,
            end_time,
            poster_url,
            organizer_id,
            date,
            address,
            lng,
            lat,
            venue_name,
            cleaned_name,
            organizer_type,
            city,
            state,
            sales_status,
            vendor_exclusivity,
            min_date,
            max_date
        ) VALUES (
            gen_random_uuid(),
            current_timestamp,
            'Event ' || i,
            'Welcome to the Card Extravaganza! 🏆🏀🏈⚾️

						Join us for a thrilling weekend celebration of sports memorabilia and card collecting. Whether you''re a seasoned collector or new to the hobby, this event is your gateway to the exciting world of sports cards.

						What to Expect:
						- Vast Selection: Browse through thousands of vintage and modern sports cards from all major sports.
						- Meet the Pros: Get autographs and photo ops with legendary athletes (schedule TBA).
						- Trading Floor: Connect with fellow collectors and trade your prized possessions.
						- Grading Services: On-site professional grading by PSA and BGS.

						Grab your tickets now and be part of this unforgettable celebration of sports history and collectibles!',
            '10:00:00',
            '18:00:00',
            'poster' || (floor(random() * 4 + 1)::int)::text || '.jpg',
            random_profile_id,
            future_date,
            'NYC Address ' || i,
            event_lng,
            event_lat,
            'NYC Venue ' || i,
            'nyc-event-' || i || '-' || to_char(current_date, 'MMDDYYYY'),
            'profile',
            'New York City',
            'NY',
            'SELLING_ALL',
            'APPLICATIONS',
            future_date,
            future_date
        ) RETURNING id INTO e_event_id;

        -- Insert event date
        INSERT INTO public.event_dates (
            event_id,
            start_time,
            end_time, 
            date
        ) VALUES (
            e_event_id,
            '10:00:00',
            '18:00:00',
            future_date
        );

        -- Assign random number of tags (between 3 and 8) to this event
        num_tags := floor(random() * 6 + 3)::int;
        FOR j IN 1..num_tags LOOP
            -- Select a random tag ID
            random_tag_id := tag_ids[floor(random() * array_length(tag_ids, 1) + 1)];
            
            -- Insert into event_tags if this combination doesn't already exist
            INSERT INTO public.event_tags(event_id, tag_id)
            SELECT e_event_id, random_tag_id
            WHERE NOT EXISTS (
                SELECT 1 FROM public.event_tags et
                WHERE et.event_id = e_event_id AND et.tag_id = random_tag_id
            );
        END LOOP;

	    -- Create three ticket types for this event
        -- RSVP Ticket
        INSERT INTO public.tickets(
            id,
            event_id,
            created_at,
            price,
            quantity,
            total_tickets,
            name
        ) VALUES (
            gen_random_uuid(),
            e_event_id,
            current_timestamp,
            0,
            200,
            200,
            'RSVP'
        );

        -- General Admission Ticket
        INSERT INTO public.tickets(
            id,
            event_id,
            created_at,
            price,
            quantity,
            total_tickets,
            name
        ) VALUES (
            gen_random_uuid(),
            e_event_id,
            current_timestamp,
            5,
            100,
            100,
            'General Admission'
        );

        -- VIP Ticket
        INSERT INTO public.tickets(
            id,
            event_id,
            created_at,
            price,
            quantity,
            total_tickets,
            name,
            description
        ) VALUES (
            gen_random_uuid(),
            e_event_id,
            current_timestamp,
            20,
            50,
            50,
            'VIP',
            'VIP entry ticket with special perks, including early access and a gift bag.'
        );

        -- create table
        INSERT INTO public.tables(
                id,
                event_id,
                price,
                quantity,
                total_tables,
                section_name,
                table_provided,
                space_allocated,
                number_vendors_allowed
        ) VALUES (
                gen_random_uuid(),
                e_event_id,
                100, 
                125,
                125,
                'Ballroom',
                true,
                20,
                2
        ) RETURNING id into e_table_id;

        -- create 75 event vendors with orders and line items except for event 10 which will be empty
        IF i != 10 THEN 
            DECLARE
                inserted_count INT := 0;
                max_attempts INT := 1000;  -- Prevent infinite loop
                attempt_count INT := 0;
                inserted_row_count INT;
                inserted_vendor_id UUID;
                inserted_order_id INT;
                tag_ids UUID[];
                vendor_status TEXT[];
                payment_status TEXT[];
                vendor_payment_status public."Payment Status";
            BEGIN
                -- Fetch all tag IDs
                SELECT ARRAY(SELECT tag_id FROM public.event_tags WHERE event_id = e_event_id) INTO tag_ids;

                -- Vendor application status options
                vendor_status := ARRAY['ACCEPTED', 'PENDING', 'REJECTED'];

                -- Payment status options for ACCEPTED vendors
                payment_status := ARRAY['PAID', 'UNPAID'];

                WHILE inserted_count < 75 AND attempt_count < max_attempts LOOP
                    WITH available_profiles AS (
                        SELECT p.id, p.email
                        FROM public.profiles p
                        WHERE p.id = ANY(profile_ids)
                        AND NOT EXISTS (
                            SELECT 1 
                            FROM public.event_vendors ev
                            WHERE ev.event_id = e_event_id
                            AND ev.vendor_id = p.id
                        )
                    ),
                    selected_profile AS (
                        SELECT id, email
                        FROM available_profiles
                        ORDER BY random()
                        LIMIT 1
                    ),
                    vendor_application_status AS (
                        SELECT vendor_status[floor(random() * array_length(vendor_status, 1) + 1)] AS status
                    )
                    INSERT INTO public.event_vendors(
                        event_id, 
                        vendor_id,
                        table_id,
                        application_status,
                        payment_status,
                        table_quantity,
                        vendors_at_table,
                        inventory,
                        application_phone,
                        application_email
                    )
                    SELECT
                        e_event_id,
                        sp.id,
                        e_table_id,
                        CASE 
                            WHEN i = 1 THEN 'ACCEPTED'::public."Application Status"
                            ELSE vas.status::public."Application Status"
                        END,
                        CASE 
                            WHEN i = 1 THEN 'PAID'::public."Payment Status"
                            WHEN vas.status = 'ACCEPTED' THEN 
                                payment_status[floor(random() * array_length(payment_status, 1) + 1)]::public."Payment Status"
                            ELSE 'UNPAID'
                        END,
                        1,
                        2,
                        'Sports Cards, Memorabilia, Autographs',
                        '555-555-5555',
                        sp.email
                    FROM selected_profile sp, vendor_application_status vas
                    RETURNING vendor_id INTO inserted_vendor_id;

                    GET DIAGNOSTICS inserted_row_count = ROW_COUNT;

                    IF inserted_row_count > 0 AND inserted_vendor_id IS NOT NULL THEN
                        -- Assign random number of tags (between 1 and 3) to this vendor
                        num_tags := floor(random() * 3 + 1)::int;
                        FOR j IN 1..num_tags LOOP
                            -- Select a random tag ID
                            random_tag_id := tag_ids[floor(random() * array_length(tag_ids, 1) + 1)];
                            
                            -- Insert into vendor_tags if this combination doesn't already exist
                            INSERT INTO public.event_vendor_tags(event_id, vendor_id, tag_id)
                            SELECT e_event_id, inserted_vendor_id, random_tag_id
                            WHERE NOT EXISTS (
                                SELECT 1 FROM public.event_vendor_tags vt
                                WHERE vt.event_id = e_event_id 
                                AND vt.vendor_id = inserted_vendor_id 
                                AND vt.tag_id = random_tag_id
                            );
                        END LOOP;

                        -- Create order and line item if vendor is PAID
                        SELECT ev.payment_status INTO vendor_payment_status FROM public.event_vendors ev
                        WHERE vendor_id = inserted_vendor_id AND event_id = e_event_id;

                        IF vendor_payment_status = 'PAID' THEN
                            INSERT INTO public.orders(
                                event_id,
                                customer_id,
                                amount_paid,
                                created_at
                            ) 
                            SELECT 
                                e_event_id,
                                inserted_vendor_id,
                                price,
                                current_timestamp - (random() * interval '30 days')
                            FROM public.tables 
                            WHERE id = e_table_id 
                            RETURNING id INTO inserted_order_id;

                            INSERT INTO public.line_items(
                                order_id,
                                quantity,
                                price,
                                item_id,
                                item_type
                            ) 
                            SELECT
                                inserted_order_id,
                                1,
                                price,
                                e_table_id,
                                'TABLE'
                            FROM public.tables 
                            WHERE id = e_table_id;
                        END IF;
                        inserted_count := inserted_count + 1;
                    END IF;
                    attempt_count := attempt_count + 1;
                END LOOP;
                IF inserted_count < 75 THEN
                    RAISE EXCEPTION 'Could not insert 75 unique vendors after % attempts. Only inserted %', max_attempts, inserted_count;
                END IF;
            END;
        END IF;
        
        -- Add 100 tickets to Event 1
        IF i = 1 THEN
            DECLARE
                attendee_id UUID;
                ticket_ids UUID[];
                inserted_ticket_id UUID;
                inserted_order_id INT;
            BEGIN
                -- Create 50 1 quantity tickets in event_tickets
                FOR j IN 1..50 LOOP
                    attendee_id := profile_ids[floor(random() * array_length(profile_ids, 1) + 1)];
                    ticket_ids := ARRAY(SELECT id FROM public.tickets WHERE event_id = e_event_id);
                    inserted_ticket_id := ticket_ids[floor(random() * array_length(ticket_ids, 1) + 1)];

                    INSERT INTO public.event_tickets(
                        event_id,
                        attendee_id,
                        ticket_id,
                        email
                    ) SELECT 
                        e_event_id,
                        attendee_id,
                        inserted_ticket_id,
                        p.email
                    FROM public.profiles p
                    WHERE id = attendee_id;

                    -- Create orders and line items
                    INSERT INTO public.orders(
                        event_id,
                        customer_id,
                        amount_paid,
                        created_at
                    ) SELECT
                        e_event_id,
                        attendee_id,
                        t.price,
                        current_timestamp - (random() * interval '20 days')
                    FROM public.tickets t
                    WHERE id = inserted_ticket_id
                    RETURNING id INTO inserted_order_id;

                    INSERT INTO public.line_items(
                        order_id,
                        quantity,
                        price,
                        item_id,
                        item_type
                    ) SELECT
                        inserted_order_id,
                        1,
                        t.price,
                        inserted_ticket_id,
                        'TICKET'
                    FROM public.tickets t
                    WHERE id = inserted_ticket_id;
                END LOOP;

                -- Create 25 2 quantity tickets in event_tickets
                FOR j IN 1..25 LOOP
                    attendee_id := profile_ids[floor(random() * array_length(profile_ids, 1) + 1)];
                    ticket_ids := ARRAY(SELECT id FROM public.tickets WHERE event_id = e_event_id);
                    inserted_ticket_id := ticket_ids[floor(random() * array_length(ticket_ids, 1) + 1)];

                    INSERT INTO public.event_tickets(
                        event_id,
                        attendee_id,
                        ticket_id,
                        email
                    ) SELECT 
                        e_event_id,
                        attendee_id,
                        inserted_ticket_id,
                        p.email
                    FROM public.profiles p
                    WHERE id = attendee_id;

                    -- Create orders and line items
                    INSERT INTO public.orders(
                        event_id,
                        customer_id,
                        amount_paid,
                        created_at
                    ) SELECT
                        e_event_id,
                        attendee_id,
                        t.price * 2,
                        current_timestamp - (random() * interval '40 days')
                    FROM public.tickets t
                    WHERE id = inserted_ticket_id
                    RETURNING id INTO inserted_order_id;

                    INSERT INTO public.line_items(
                        order_id,
                        quantity,
                        price,
                        item_id,
                        item_type
                    ) SELECT
                        inserted_order_id,
                        2,
                        t.price,
                        inserted_ticket_id,
                        'TICKET'
                    FROM public.tickets t
                    WHERE id = inserted_ticket_id;
                END LOOP;

                -- Create 25 3 quantity tickets in event_tickets
                FOR j IN 1..25 LOOP
                    attendee_id := profile_ids[floor(random() * array_length(profile_ids, 1) + 1)];
                    ticket_ids := ARRAY(SELECT id FROM public.tickets WHERE event_id = e_event_id);
                    inserted_ticket_id := ticket_ids[floor(random() * array_length(ticket_ids, 1) + 1)];

                    INSERT INTO public.event_tickets(
                        event_id,
                        attendee_id,
                        ticket_id,
                        email
                    ) SELECT 
                        e_event_id,
                        attendee_id,
                        inserted_ticket_id,
                        p.email
                    FROM public.profiles p
                    WHERE id = attendee_id;

                    -- Create orders and line items
                    INSERT INTO public.orders(
                        event_id,
                        customer_id,
                        amount_paid,
                        created_at
                    ) SELECT
                        e_event_id,
                        attendee_id,
                        t.price * 3,
                        current_timestamp - (random() * interval '20 days')
                    FROM public.tickets t
                    WHERE id = inserted_ticket_id
                    RETURNING id INTO inserted_order_id;

                    INSERT INTO public.line_items(
                        order_id,
                        quantity,
                        price,
                        item_id,
                        item_type
                    ) SELECT
                        inserted_order_id,
                        3,
                        t.price,
                        inserted_ticket_id,
                        'TICKET'
                    FROM public.tickets t
                    WHERE id = inserted_ticket_id;
                END LOOP;
            END;
        END IF;
    END LOOP;
END $$;


INSERT INTO public.event_categories (event_id, category_id)
SELECT events.id, categories.id
FROM public.events
JOIN public.categories ON categories.name = 'collectables';

RESET ALL;