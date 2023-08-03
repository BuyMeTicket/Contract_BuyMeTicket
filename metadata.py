import os
import json


def generate_metadata_json(directory_path):
    # 取得目錄中所有的檔案
    files = os.listdir(directory_path)

    # 確認 jsons 目錄存在，如果不存在則建立
    jsons_directory = 'jsons'
    if not os.path.exists(jsons_directory):
        os.makedirs(jsons_directory)

    # 迭代處理每個檔案
    for i, file in enumerate(files):
        # 假設檔案名稱就是 NFT 的名稱
        name = os.path.splitext(file)[0]
        description = f"Introducing a captivating NFT from the world of style: '{os.path.splitext(file)[0]}'. Immerse yourself in the artistic realm of style with this extraordinary creation."
        image_uri = ''  # 暫時空著，待後續更新

        # 建立 metadata 字典
        metadata = {
            'name': name,
            'description': description,
            'image': image_uri,
            'attributes': [
                {
                    'trait_type': 'Architectural Style',
                    'value': 'style'  # 暫時空著，待後續更新
                }
            ]
        }

        # 寫入 metadata 到 JSON 檔案
        json_file_name = f'{i}.json'
        json_file_path = os.path.join(jsons_directory, json_file_name)
        with open(json_file_path, 'w') as json_file:
            json.dump(metadata, json_file, indent=4)

        print(f"Generated metadata JSON file: {json_file_path}")

    # 執行完畢後，呼叫函式更新圖片的 URI


def update_metadata_imageURI(jsons, base_uri):
    # 取得目錄中所有的檔案
    files = os.listdir(jsons)

    # 迭代處理每個檔案
    for file in files:
        # 檢查是否為 JSON 檔案
        if file.endswith('.json'):
            json_file_path = os.path.join(jsons, file)

            # 讀取 JSON 檔案
            with open(json_file_path, 'r+') as json_file:
                metadata = json.load(json_file)
                name = metadata['name']
                image_filename = f"{name}.png"
                image_uri = f"{base_uri}/{image_filename}"
                metadata['image'] = image_uri

                # 將更新後的 metadata 寫回 JSON 檔案
                json_file.seek(0)
                json.dump(metadata, json_file, indent=4)
                json_file.truncate()

                print(
                    f"Updated image URI in metadata JSON file: {json_file_path}")


directory_path = 'images/'  # 請替換成您的圖片目錄路徑
base_uri = 'ipfs://'  # 請替換成您的 IPFS Gateway URI


generate_metadata_json(directory_path)
update_metadata_imageURI('jsons', base_uri)
