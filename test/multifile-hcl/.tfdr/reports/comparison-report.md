# Terraform 環境間差分レポート (基準: env1)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env1` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 24 |

## 認識済み差分 (ignore.json)

| 属性パス | env1 → env2 | 理由 |
| :--- | :--- | :--- |
| /resource/google_compute_firewall/allow_app | + [<br>&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;"allow": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"ports": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"8080"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;],<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"protocol": "tcp"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;&nbsp;&nbsp;],<br>&nbsp;&nbsp;&nbsp;&nbsp;"direction": "INGRESS",<br>&nbsp;&nbsp;&nbsp;&nbsp;"labels": {<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"environment": "env2",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"module": "database",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"tier": "production"<br>&nbsp;&nbsp;&nbsp;&nbsp;},<br>&nbsp;&nbsp;&nbsp;&nbsp;"name": "allow-app-env2",<br>&nbsp;&nbsp;&nbsp;&nbsp;"network": "\${google_compute_network.main.name}",<br>&nbsp;&nbsp;&nbsp;&nbsp;"target_tags": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"env2",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"app"<br>&nbsp;&nbsp;&nbsp;&nbsp;]<br>&nbsp;&nbsp;}<br>] | New firewall rule for app server created in env2 only |
| /resource/google_compute_firewall/allow_http/0/allow/0/ports/1 | + 443 | HTTPS port added to firewall rule in env2 |
| /resource/google_compute_firewall/allow_http/0/labels/environment | ~ env1<br>→ env2 | Environment label differs: env1 -> env2 |
| /resource/google_compute_firewall/allow_http/0/labels/tier | + production | Tier label added in env2 (production) |
| /resource/google_compute_firewall/allow_http/0/name | ~ allow-http-env1<br>→ allow-http-env2 | Firewall rule name differs per environment |
| /resource/google_compute_firewall/allow_http/0/target_tags/0 | ~ env1<br>→ env2 | Target tags updated: env1 -> env2 |
| /resource/google_compute_firewall/allow_http/0/target_tags/2 | + app | App tag added to firewall rule in env2 |
| /resource/google_compute_instance/app | + [<br>&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;"boot_disk": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"initialize_params": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"image": "debian-11",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"size": 50<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;&nbsp;&nbsp;],<br>&nbsp;&nbsp;&nbsp;&nbsp;"labels": {<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"environment": "env2",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"module": "compute",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"role": "app",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"tier": "production"<br>&nbsp;&nbsp;&nbsp;&nbsp;},<br>&nbsp;&nbsp;&nbsp;&nbsp;"machine_type": "e2-standard-2",<br>&nbsp;&nbsp;&nbsp;&nbsp;"name": "app-server-env2",<br>&nbsp;&nbsp;&nbsp;&nbsp;"network_interface": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"network": "\${google_compute_network.main.name}"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;&nbsp;&nbsp;],<br>&nbsp;&nbsp;&nbsp;&nbsp;"tags": [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"env2",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"app",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"managed",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"scaled"<br>&nbsp;&nbsp;&nbsp;&nbsp;],<br>&nbsp;&nbsp;&nbsp;&nbsp;"zone": "us-central1-a"<br>&nbsp;&nbsp;}<br>] | New app server instance created in env2 only |
| /resource/google_compute_instance/web/0/boot_disk/0/initialize_params/0/size | ~ 20<br>→ 50 | Boot disk size increased: 20GB -> 50GB |
| /resource/google_compute_instance/web/0/labels/environment | ~ env1<br>→ env2 | Environment label differs: env1 -> env2 |
| /resource/google_compute_instance/web/0/labels/tier | + production | Tier label added in env2 (production) |
| /resource/google_compute_instance/web/0/machine_type | ~ e2-medium<br>→ e2-standard-2 | Machine type scaled: e2-medium -> e2-standard-2 |
| /resource/google_compute_instance/web/0/name | ~ web-server-env1<br>→ web-server-env2 | Instance name differs per environment |
| /resource/google_compute_instance/web/0/tags/0 | ~ env1<br>→ env2 | Tags updated: env1 -> env2 |
| /resource/google_compute_instance/web/0/tags/3 | + scaled | Scaled tag added in env2 |
| /resource/google_compute_network/main/0/labels/environment | ~ env1<br>→ env2 | Environment label differs: env1 -> env2 |
| /resource/google_compute_network/main/0/labels/tier | + production | Tier label added in env2 (production) |
| /resource/google_compute_network/main/0/name | ~ network-env1<br>→ network-env2 | Network name differs per environment |
| /resource/google_sql_database_instance/main/0/labels/environment | ~ env1<br>→ env2 | Environment label differs: env1 -> env2 |
| /resource/google_sql_database_instance/main/0/labels/tier | + production | Tier label added in env2 (production) |
| /resource/google_sql_database_instance/main/0/name | ~ database-env1<br>→ database-env2 | Database instance name differs per environment |
| /resource/google_sql_database_instance/main/0/settings/0/backup_configuration/0/enabled | ~ false<br>→ true | Backup enabled in env2 |
| /resource/google_sql_database_instance/main/0/settings/0/backup_configuration/0/point_in_time_recovery_enabled | + true | Point-in-time recovery enabled in env2 |
| /resource/google_sql_database_instance/main/0/settings/0/tier | ~ db-f1-micro<br>→ db-custom-2-8192 | Database tier scaled: db-f1-micro -> db-custom-2-8192 |


