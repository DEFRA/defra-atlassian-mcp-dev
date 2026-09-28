#!/bin/bash

# Local AWS resources for the hub. Add app buckets and queues here — this runs
# before 99-ready.sh, which releases the floci healthcheck.

# S3 buckets

# Destination for documents uploaded through cdp-uploader. Nothing reads it
# yet; the bucket exists so the upload flow has somewhere to land.
aws s3 mb --endpoint-url=http://localhost:4566 s3://atlassian-space-handling-forms || true
