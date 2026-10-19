resource "aws_dynamodb_table" "url_table" {
  name         = "${var.group_number}-url-shortener-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_id"

  attribute {
    name = "short_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
