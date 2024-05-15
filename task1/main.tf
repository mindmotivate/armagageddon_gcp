# Define a Google Cloud Storage (GCS) bucket resource
resource "google_storage_bucket" "malgus_gcp" {
  name                     = "malgus_gcp"
  storage_class            = "standard"  # Set the storage class for the bucket
  location                 = "us-central1"  # Define the location for the bucket
  labels = {
    "env" = "armageddon"  # Add environment label to the bucket
    "dep" = "classfive"     # Add deployment label to the bucket
  }
  #uniform_bucket_level_access = true  # Enable uniform bucket-level access

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # Define lifecycle rules for the bucket (optional)
  # lifecycle_rule {
  #   condition {
  #     age = 5  # Set the age condition for the rule
  #   }
  #   action {
  #     type          = "SetStorageClass"  # Define action type as SetStorageClass
  #     storage_class = "STANDARD"          # Set the storage class for the action
  #   }
  # }

  # Define retention policy for the bucket (optional)
  # retention_policy {
  #   is_locked        = false    # Specify if retention policy is locked
  #   retention_period = 864000   # Set the retention period in seconds
  # }
}

# Define a Google Cloud Storage (GCS) bucket object for a picture
resource "google_storage_bucket_object" "theo_jpeg" {
  name   = "theo.jpeg"                                    # Set the name of the object
  bucket = google_storage_bucket.malgus_gcp.name                  # Specify the bucket name
  source = "${path.module}/theo.jpeg" 
  content_type = "image/jpeg"                       # Define the relative source file path for the object
}

# Define a Google Cloud Storage (GCS) bucket object for an HTML file
resource "google_storage_bucket_object" "index_html" {
  name   = "index.html"                                    # Set the name of the object
  bucket = google_storage_bucket.malgus_gcp.name                  # Specify the bucket name
  source = "${path.module}/index.html"
  content_type = "text/html"               # Define the relative source file path for the object
}


resource "google_storage_default_object_access_control" "maglus_gcp_public_access" {
  bucket = google_storage_bucket.malgus_gcp.name
  role   = "READER"
  entity = "allUsers"
 }




resource "google_storage_bucket_iam_binding" "public_access" {
  bucket = google_storage_bucket.malgus_gcp.name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers",
  ]
}


# Output the self-link URL of the index HTML object
output "malgus_bucket_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.malgus_gcp.name}/index.html"
}

