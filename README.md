はじめに
=======

「開発サーバのようなEC2 Instanceを起動しっぱなしにしていると、お金の無駄だよね」という発想のもと作ったものです。

* LDAP アカウントでログインします
* 最初、対象としたいAWSのテナント毎にIAM Roleを設定する必要があります（IAM Roleの設定はシステクに依頼してください）
* EC2 Instance毎に、このConsoleでStart/Stopを許可するか、という設定(Lock/Unlock)があります。
* Lock/Unlock は 右上のアイコンをクリックして、 Admin Passwordを入力すると変更できます。今はだれでもこのAdminPasswordが閲覧できますが、ご愛嬌。
* UnlockされているEC2 Instanceは start / stop ボタンが表示され、Start/Stopができます
* また、スケジュールが入力できて、曜日・時間帯 を指定して、Start/stopする時間を設定できます
* Stop Onlyのスケジュールも指定可能です（消し忘れ防止の用途）

注意
-----
* サービスしているInstanceをUnlockするのは危険なのでやめましょう。


IAM Role の 設定
-------------------

下記のようにしてください。

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1384933267000",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1384933267001",
            "Effect": "Allow",
            "Action": [
                "ec2:RebootInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "ec2:ResourceTag/APIStartStop": "YES"
                }
            },
            "Resource": [
                "arn:aws:ec2:*"
            ]
        },
        {
            "Sid": "Stmt1386654386000",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1389937836000",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

