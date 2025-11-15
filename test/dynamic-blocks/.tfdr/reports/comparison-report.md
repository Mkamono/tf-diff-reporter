# Terraform 環境間差分レポート (基準: env1)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env1` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 10 |

## 認識済み差分 (ignore.json)

| 属性パス | env1 → env2 | 理由 |
| :--- | :--- | :--- |
| /locals/0/egress_rules/1 | + {<br>&nbsp;&nbsp;"ports": [<br>&nbsp;&nbsp;&nbsp;&nbsp;"3306"<br>&nbsp;&nbsp;],<br>&nbsp;&nbsp;"protocol": "tcp"<br>} | MySQL egress rule added in env2 |
| /locals/0/env | ~ env1<br>→ env2 | Environment name differs: env1 -> env2 |
| /locals/0/ingress_rules/0/sources/0 | ~ 0.0.0.0/0<br>→ 10.0.0.0/8 | SSH source restricted: 0.0.0.0/0 -> 10.0.0.0/8 |
| /locals/0/ingress_rules/2 | + {<br>&nbsp;&nbsp;"ports": [<br>&nbsp;&nbsp;&nbsp;&nbsp;"443"<br>&nbsp;&nbsp;],<br>&nbsp;&nbsp;"protocol": "tcp",<br>&nbsp;&nbsp;"sources": [<br>&nbsp;&nbsp;&nbsp;&nbsp;"0.0.0.0/0"<br>&nbsp;&nbsp;]<br>} | HTTPS ingress rule added in env2 |
| /locals/1/env_vars/API_VERSION | + v2 | API version added: v2 |
| /locals/1/env_vars/DEBUG | ~ false<br>→ true | Debug mode enabled: false -> true |
| /locals/1/env_vars/LOG_LEVEL | ~ info<br>→ debug | Log level changed: info -> debug |
| /resource/google_cloud_run_service/api/0/template/0/spec/0/containers/0/image | ~ gcr.io/my-project/api:v1<br>→ gcr.io/my-project/api:v2 | Container image updated: v1 -> v2 |
| /resource/google_cloud_run_service/api/0/template/0/spec/0/containers/0/resources/0/limits/cpu | ~ 1<br>→ 2 | CPU scaled: 1 -> 2 |
| /resource/google_cloud_run_service/api/0/template/0/spec/0/containers/0/resources/0/limits/memory | ~ 512Mi<br>→ 1Gi | Memory scaled: 512Mi -> 1Gi |


