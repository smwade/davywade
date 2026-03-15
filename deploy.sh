#!/bin/bash

echo "Building Astro project..."

npm run build

if [ $? -ne 0 ]; then
  echo "Build failed."
  exit 1
fi

echo "Starting S3 deployment..."

aws s3 sync dist/ s3://davywade.com --delete \
  --exclude ".DS_Store"

if [ $? -eq 0 ]; then
  echo "S3 deployment completed successfully."
else
  echo "S3 deployment failed."
  exit 1
fi

echo "Creating CloudFront invalidation..."

aws cloudfront create-invalidation --distribution-id E224XV2L8RZLIS --paths "/*"

if [ $? -eq 0 ]; then
  echo "CloudFront invalidation completed successfully."
else
  echo "CloudFront invalidation failed."
fi
