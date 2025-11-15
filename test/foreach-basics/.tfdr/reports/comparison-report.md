# Terraform 環境間差分レポート (基準: env1)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env1` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 12 |

## 認識済み差分 (ignore.json)

| 属性パス | env1 → env2 | 理由 |
| :--- | :--- | :--- |
| /resource/google_compute_instance/web_servers/0/for_each/frontend-3 | + 10.0.1.12 | New frontend-3 instance added in env2 |
| /resource/google_compute_instance/web_servers/0/labels/env | ~ env1<br>→ env2 | Environment label differs: env1 -> env2 |
| /resource/google_compute_instance/web_servers/0/machine_type | ~ e2-medium<br>→ e2-standard-2 | Machine type upgraded: e2-medium -> e2-standard-2 |
| /resource/google_compute_instance/web_servers/0/tags/0 | ~ env1<br>→ env2 | Tags differ per environment: env1 -> env2 |
| /resource/google_service_account/services/0/account_id | ~ app-\${each.value}-env1<br>→ app-\${each.value}-env2 | Service account ID suffix differs: env1 -> env2 |
| /resource/google_service_account/services/0/description | ~ Service account for \${each.value} in env1<br>→ Service account for \${each.value} in env2 | Service account description suffix differs: env1 -> env2 |
| /resource/google_service_account/services/0/display_name | ~ App \${each.value} Service Account (env1)<br>→ App \${each.value} Service Account (env2) | Service account display name suffix differs: env1 -> env2 |
| /resource/google_service_account/services/0/for_each | ~ \${toset(["api", "worker", "scheduler"])}<br>→ \${toset(["api", "worker", "scheduler", "monitor"])} | Services extended with monitor account in env2 |
| /resource/google_storage_bucket/app_buckets/0/for_each/archive | + ARCHIVE | New archive bucket added in env2 |
| /resource/google_storage_bucket/app_buckets/0/for_each/data | ~ NEARLINE<br>→ STANDARD | Data bucket storage class changed: NEARLINE -> STANDARD |
| /resource/google_storage_bucket/app_buckets/0/labels/env | ~ env1<br>→ env2 | Environment label differs: env1 -> env2 |
| /resource/google_storage_bucket/app_buckets/0/name | ~ app-bucket-\${each.key}-env1<br>→ app-bucket-\${each.key}-env2 | Bucket name suffix differs per environment |


