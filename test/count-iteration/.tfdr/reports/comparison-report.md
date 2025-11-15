# Terraform 環境間差分レポート (基準: env1)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env1` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 7 |

## 認識済み差分 (ignore.json)

| 属性パス | env1 → env2 | 理由 |
| :--- | :--- | :--- |
| /locals/0/enable_backup | ~ false<br>→ true | Backup feature enabled in env2 (false -> true) |
| /locals/0/enable_https | ~ false<br>→ true | HTTPS feature enabled in env2 (false -> true) |
| /locals/0/env | ~ env1<br>→ env2 | Environment name differs: env1 -> env2 |
| /locals/0/replica_count | ~ 1<br>→ 2 | Replica count increased: 1 -> 2 |
| /resource/google_compute_instance/replicas/0/machine_type | ~ e2-medium<br>→ e2-standard-2 | Replica machine type scaled: e2-medium -> e2-standard-2 |
| /resource/google_sql_database_instance/primary/0/settings/0/tier | ~ db-f1-micro<br>→ db-custom-2-8192 | Database tier scaled: db-f1-micro -> db-custom-2-8192 |
| /resource/google_storage_bucket/data/0/storage_class | ~ NEARLINE<br>→ COLDLINE | Storage class changed: NEARLINE -> COLDLINE for backup |


