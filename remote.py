import requests
from pathlib import Path

def remfileinstall(session,url,dst):
    try:
        with session.get(url, stream=True,timeout=10) as req:
            req.raise_for_status()
            tsize = int(req.headers.get("content-length", 0))
            print(f"total size = {tsize// 1048576} MB", flush=True)
            downloaded = 0
            with open(dst,"wb") as f:
                for chunk in req.iter_content(chunk_size=512000):
                    f.write(chunk)
                    downloaded += len(chunk)
                    print(f"\rtotal downloaded size = {downloaded // 1048576} MB", end="", flush=True)
            print()
    except:
        print("file remote installation failed mid install")
        dst.unlink(missing_ok=True)
        return None

    return dst


def gtlatest(session,pkg):
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.name}/releases/latest"
    print(f"{pkg.name}: Querying for latest release; current : {pkg.version}")
    try:
        res = session.get(url,timeout=5)
        res.raise_for_status()
        resJson = res.json()
        return resJson
    except requests.exceptions.JSONDecodeError as e:
        print(f"Invalid JSON response: {e}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"The request failed: {e}")
        return None
