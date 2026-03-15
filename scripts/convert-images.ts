import fs from 'node:fs/promises';
import path from 'node:path';
import convert from 'heic-convert';
import sharp from 'sharp';

const INPUT_DIR = './photos';
const OUTPUT_DIR = './public/images';
const MANIFEST_PATH = './src/data/photos.json';

async function main() {
  await fs.mkdir(OUTPUT_DIR, { recursive: true });
  await fs.mkdir(path.dirname(MANIFEST_PATH), { recursive: true });

  const files = await fs.readdir(INPUT_DIR);
  const heicFiles = files.filter(f => f.toLowerCase().endsWith('.heic'));

  console.log(`Found ${heicFiles.length} HEIC files.`);

  const photoManifest = [];

  for (const file of heicFiles) {
    const inputPath = path.join(INPUT_DIR, file);
    const baseName = path.parse(file).name;
    const outputPath = path.join(OUTPUT_DIR, `${baseName}.webp`);

    console.log(`Processing ${file}...`);

    try {
      const inputBuffer = await fs.readFile(inputPath);
      
      // Convert HEIC to JPEG buffer first (as sharp might not support HEIC)
      const jpegBuffer = await convert({
        buffer: inputBuffer,
        format: 'JPEG',
        quality: 1
      });

      // Use sharp to convert to optimized WebP
      const info = await sharp(jpegBuffer as Buffer)
        .webp({ quality: 85 })
        .toFile(outputPath);

      photoManifest.push({
        id: baseName,
        src: `/images/${baseName}.webp`,
        width: info.width,
        height: info.height,
        aspectRatio: info.width / info.height
      });

      console.log(`Generated ${outputPath}`);
    } catch (error) {
      console.error(`Failed to process ${file}:`, error);
    }
  }

  await fs.writeFile(MANIFEST_PATH, JSON.stringify(photoManifest, null, 2));
  console.log(`Manifest written to ${MANIFEST_PATH}`);
}

main().catch(console.error);
