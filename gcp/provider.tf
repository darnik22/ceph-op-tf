variable "google_project" {}
variable "google_region" {}
variable "google_zone" {}
variable "google_keyfile_json" {}

provider "google" {
  project = var.google_project
  region  = var.google_region
  zone    = var.google_zone
  credentials = file("${var.google_keyfile_json}")
}
