return {
  "David-Kunz/gen.nvim",
  cmd = "Gen",
  opts = {
    model = "s3-chef",
    host = "localhost",
    port = "11434",
    display_mode = "float", -- Opens a clean floating window while generating
    show_prompt = false,
    show_model = true,
    no_auto_close = false,
    -- Do not let the plugin try to start a local ollama binary, since we use Docker:
    init = function() end,
  },
  config = function(_, opts)
    local gen = require("gen")
    gen.setup(opts)

    gen.prompts["S3_Policy_From_Selection"] = {
      prompt = "Write a valid AWS S3 bucket policy in JSON for the following requirement. Output ONLY the JSON code inside standard markdown backticks:\n\n$text",
      replace = true,
      extract = "```[^\n]*\n(.-)```",
    }

    gen.prompts["S3_Policy_Ask"] = {
      prompt = "Write a valid AWS S3 bucket policy in JSON for the following requirement: $input. Output ONLY the JSON code.",
      replace = false,
    }
    -- Inside your gen.nvim config in lua/plugins/llm.lua
    gen.prompts["Rgw_Bucket_Policy"] = {
      prompt = [[You are a Ceph RADOSGW S3 policy generator. Convert the following specification into a valid JSON bucket policy.
        Strict Rules:
        1. Return ONLY the JSON code inside standard markdown backticks, no explanations.
        2. Top-level fields: "Version": "2012-10-17", "Id": "<bucket_name>", "Statement": [...]
        3. Principal format: "Principal": { "AWS": [ "arn:aws:iam:::user/<username>" ] }
        4. Resource format for EVERY statement: [ "arn:aws:s3:::<bucket_name>", "arn:aws:s3:::<bucket_name>/*" ]
        5. Base actions to ALWAYS include alongside requested permissions whenever PutObject or GetObject is used:
        "s3:PutObjectTagging", "s3:GetObjectTagging", "s3:GetObjectVersion", "s3:GetObjectVersionTagging", "s3:ListMultipartUploadParts"
        6. Map requested permissions to S3 actions (e.g., list-bucket -> s3:ListBucket, read -> s3:GetObject, write/put -> s3:PutObject, delete -> s3:DeleteObject) and generate a descriptive "Sid".

        Specification to convert:
        $text]],
      replace = true,
      extract = "```[^\n]*\n(.-)```",
    }
  end,
  keys = {
    -- Visual Mode: Highlight a comment/description and press <leader>sp to replace it with an S3 policy
    { "<leader>sp", ":Gen S3_Policy_From_Selection<CR>", mode = { "v" }, desc = "Generate S3 Policy from selection" },
    -- Normal Mode: Press <leader>sa to type what you want in a prompt box
    { "<leader>sa", ":Gen S3_Policy_Ask<CR>", mode = { "n" }, desc = "Ask LLM for an S3 Policy" },
    -- General AI menu
    { "<leader>ai", ":Gen<CR>", mode = { "n", "v" }, desc = "Open Local LLM Menu" },
  },
}
