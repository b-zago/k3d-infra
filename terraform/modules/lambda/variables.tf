variable "lambda_func" {
  type = object({
    source_file   = string
    role          = string
    function_name = string
    handler       = string
    runtime       = string
  })
}
