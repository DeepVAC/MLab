import requests
import json


def createtask(src, dest="/", host=None, port=5212, admin="admin@cloudreve.org", passwd=None, uid=1, policy_id=1):
    """
    @src 服务器上的绝对路径，未修改时一般为 /cloudreve/uploads/*，必填
    @dest 相对路径，每个用户都有自己的根目录，值为 "/*"
    @host 文件服务域名，必填
    @port 文件服务端口，必填
    @admin 管理员账户邮箱，必填
    @passwd 管理员账户密码，必填
    @uid    要创建导入文件任务的用户id
    @policy_id 要创建的导入文件任务的存储策略id
    """
    # 实例化session
    session = requests.session()
    # 目标url
    url = "http://{}:{}/api/v3/user/session".format(host, port)
    # 管理员账户密码
    payload = "{\"userName\":\"{}\",\"Password\":\"{}\",\"captchaCode\":\"\"}".format(
        admin, passwd)
    headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36',
        'Content-Type': 'application/json'
    }

    # 使用session发起请求
    response = session.post(url, headers=headers, data=payload)

    if response.status_code == 200:
        url = "http:/{}:{}/api/v3/admin/task/import".format(host, port)
        payload = {"uid": uid, "policy_id": policy_id,
                   "src": src, "dst": dest, "recursive": True}
        response = session.post(url, headers=headers, data=json.dumps(payload))

        if response.status_code == 200:
            print(response.text)


if __name__ == "__main__":
    createtask("/cloudreve/uploads/1/demo",
               host="ai1.gemfield.org", passwd="xxxxx")
