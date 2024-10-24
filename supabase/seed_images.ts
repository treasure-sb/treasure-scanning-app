import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import { config } from "dotenv";
import path from "path";
import fs from "fs";

config({ path: ".env.local" });

const SUPABASE_SERVICE_KEY = process.env.EXPO_PUBLIC_SUPABASE_SERVICE_KEY;

async function insertPosters() {
  const supabase = createClient(
    "http://localhost:54321",
    SUPABASE_SERVICE_KEY as string,
    {
      auth: { persistSession: false },
    }
  );

  const imagePath = path.join(process.cwd(), "supabase", "images", "posters");
  const files = fs.readdirSync(imagePath);

  for (const file of files) {
    const fileContent = readFileSync(path.join(imagePath, file));

    const { error } = await supabase.storage
      .from("posters")
      .upload(file, fileContent, {
        contentType: "image/jpg",
      });

    if (error) {
      console.error("Error uploading image", error);
    }
  }
}

async function insertAvatars() {
  const supabase = createClient(
    "http://localhost:54321",
    SUPABASE_SERVICE_KEY as string,
    {
      auth: { persistSession: false },
    }
  );

  const imagePath = path.join(process.cwd(), "supabase", "images", "avatars");
  const files = fs.readdirSync(imagePath);
  const filterDefaultAvatar = files.filter(
    (file) => file !== "default_avatar.png"
  );
  for (const file of filterDefaultAvatar) {
    const fileContent = readFileSync(path.join(imagePath, file));

    const { error } = await supabase.storage
      .from("avatars")
      .upload(file, fileContent, {
        contentType: "image/jpg",
      });

    if (error) {
      console.error("Error uploading image", error);
    }
  }

  const defaultAvatarFileContent = readFileSync(
    path.join(imagePath, "default_avatar.png")
  );
  const { error } = await supabase.storage
    .from("avatars")
    .upload("default_avatar", defaultAvatarFileContent, {
      contentType: "image/png",
    });

  if (error) {
    console.error("Error uploading image", error);
  }
}

insertAvatars();
insertPosters();