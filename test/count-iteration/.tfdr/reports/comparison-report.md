# Terraform 環境間差分レポート (基準: env2)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env2` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 7 |

## 認識済み差分 (ignore.json)

| 属性パス | env2 → env1 | 理由 |
| :--- | :--- | :--- |
| /locals/0/enable_backup | ~ true<br>→ false | Backup feature enabled in env2 (false -> true) |
| /locals/0/enable_https | ~ true<br>→ false | HTTPS feature enabled in env2 (false -> true) |
| /locals/0/env | ~ env2<br>→ env1 | Environment name differs: env1 -> env2 |
| /locals/0/replica_count | ~ 2<br>→ 1 | Replica count increased: 1 -> 2 |
| /resource/google_compute_instance/replicas/0/machine_type | ~ e2-standard-2<br>→ e2-medium | Replica machine type scaled: e2-medium -> e2-standard-2 |
| /resource/google_sql_database_instance/primary/0/settings/0/tier | ~ db-custom-2-8192<br>→ db-f1-micro | Database tier scaled: db-f1-micro -> db-custom-2-8192 |
| /resource/google_storage_bucket/data/0/storage_class | ~ COLDLINE<br>→ NEARLINE | Storage class changed: NEARLINE -> COLDLINE for backup |


