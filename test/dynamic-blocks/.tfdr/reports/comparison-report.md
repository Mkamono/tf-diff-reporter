# Terraform 環境間差分レポート (基準: env2)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env2` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 10 |

## 認識済み差分 (ignore.json)

| 属性パス | env2 → env1 | 理由 |
| :--- | :--- | :--- |
| /locals/0/egress_rules/1 | − {<br>&nbsp;&nbsp;"ports": [<br>&nbsp;&nbsp;&nbsp;&nbsp;"3306"<br>&nbsp;&nbsp;],<br>&nbsp;&nbsp;"protocol": "tcp"<br>} | MySQL egress rule added in env2 |
| /locals/0/env | ~ env2<br>→ env1 | Environment name differs: env1 -> env2 |
| /locals/0/ingress_rules/0/sources/0 | ~ 10.0.0.0/8<br>→ 0.0.0.0/0 | SSH source restricted: 0.0.0.0/0 -> 10.0.0.0/8 |
| /locals/0/ingress_rules/2 | − {<br>&nbsp;&nbsp;"ports": [<br>&nbsp;&nbsp;&nbsp;&nbsp;"443"<br>&nbsp;&nbsp;],<br>&nbsp;&nbsp;"protocol": "tcp",<br>&nbsp;&nbsp;"sources": [<br>&nbsp;&nbsp;&nbsp;&nbsp;"0.0.0.0/0"<br>&nbsp;&nbsp;]<br>} | HTTPS ingress rule added in env2 |
| /locals/1/env_vars/API_VERSION | − v2 | API version added: v2 |
| /locals/1/env_vars/DEBUG | ~ true<br>→ false | Debug mode enabled: false -> true |
| /locals/1/env_vars/LOG_LEVEL | ~ debug<br>→ info | Log level changed: info -> debug |
| /resource/google_cloud_run_service/api/0/template/0/spec/0/containers/0/image | ~ gcr.io/my-project/api:v2<br>→ gcr.io/my-project/api:v1 | Container image updated: v1 -> v2 |
| /resource/google_cloud_run_service/api/0/template/0/spec/0/containers/0/resources/0/limits/cpu | ~ 2<br>→ 1 | CPU scaled: 1 -> 2 |
| /resource/google_cloud_run_service/api/0/template/0/spec/0/containers/0/resources/0/limits/memory | ~ 1Gi<br>→ 512Mi | Memory scaled: 512Mi -> 1Gi |


