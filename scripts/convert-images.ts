import fs from 'node:fs/promises';
import path from 'node:path';
import convert from 'heic-convert';
import sharp from 'sharp';

const INPUT_DIR = './photos';
const OUTPUT_DIR = './public/images';
const MANIFEST_PATH = './src/data/photos.json';

const SUPPORTED_EXTENSIONS = ['.heic', '.jpg', '.jpeg', '.png'];

async function main() {
  // Clean output dir so removed photos don't persist
  await fs.rm(OUTPUT_DIR, { recursive: true, force: true });
  await fs.mkdir(OUTPUT_DIR, { recursive: true });
  await fs.mkdir(path.dirname(MANIFEST_PATH), { recursive: true });

  const files = await fs.readdir(INPUT_DIR);
  const imageFiles = files.filter(f =>
    SUPPORTED_EXTENSIONS.includes(path.extname(f).toLowerCase())
  );

  console.log(`Found ${imageFiles.length} image files.`);

  const photoManifest = [];

  for (const file of imageFiles) {
    const inputPath = path.join(INPUT_DIR, file);
    const baseName = path.parse(file).name;
    const outputPath = path.join(OUTPUT_DIR, `${baseName}.webp`);

    console.log(`Processing ${file}...`);

    try {
      const ext = path.extname(file).toLowerCase();
      let imageBuffer: Buffer;

      if (ext === '.heic') {
        const inputBuffer = await fs.readFile(inputPath);
        imageBuffer = await convert({
          buffer: inputBuffer,
          format: 'JPEG',
          quality: 1
        }) as Buffer;
      } else {
        imageBuffer = await fs.readFile(inputPath);
      }

      const info = await sharp(imageBuffer)
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
