# Terraform 環境間差分レポート (基準: env1)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `env1` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 11 |

## 認識済み差分 (ignore.json)

| 属性パス | env1 → env2 | 理由 |
| :--- | :--- | :--- |
| /locals/0/monitoring_resources | ~ \${local.enable_monitoring ? {<br>&nbsp;&nbsp;&nbsp;&nbsp;alert-policy = {<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;display_name = "High CPU Alert"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;threshold&nbsp;&nbsp;&nbsp;&nbsp;= 80<br>&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;} : {}}<br>→ \${local.enable_monitoring ? {<br>&nbsp;&nbsp;&nbsp;&nbsp;alert-policy = {<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;display_name = "High CPU Alert"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;threshold&nbsp;&nbsp;&nbsp;&nbsp;= 80<br>&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;&nbsp;&nbsp;disk-alert = {<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;display_name = "High Disk Alert"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;threshold&nbsp;&nbsp;&nbsp;&nbsp;= 85<br>&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;} : {}} | Monitoring resources extended with disk-alert policy |
| /variable/enable_monitoring/0/default | ~ false<br>→ true | Monitoring enabled in env2 (false -> true) |
| /variable/environment/0/default | ~ env1<br>→ env2 | Environment variable default: env1 -> env2 |
| /variable/instance_config/0/default/disk_size | ~ 20<br>→ 50 | Instance disk_size increased: 20 -> 50 |
| /variable/instance_config/0/default/machine_type | ~ e2-medium<br>→ e2-standard-2 | Instance machine_type scaled: e2-medium -> e2-standard-2 |
| /variable/services/0/default/0/replicas | ~ 1<br>→ 2 | Web service replicas increased: 1 -> 2 |
| /variable/services/0/default/1/replicas | ~ 1<br>→ 3 | API service replicas increased: 1 -> 3 |
| /variable/services/0/default/2 | + {<br>&nbsp;&nbsp;"name": "worker",<br>&nbsp;&nbsp;"port": 9000,<br>&nbsp;&nbsp;"replicas": 2<br>} | Worker service added with 2 replicas |
| /variable/tags/0/default/CostCenter | ~ CC-1000<br>→ CC-2000 | Tags CostCenter updated: CC-1000 -> CC-2000 |
| /variable/tags/0/default/Environment | ~ env1<br>→ env2 | Tags Environment updated: env1 -> env2 |
| /variable/tags/0/default/Tier | + production | Tags Tier added: production |


