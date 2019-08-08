from bs4 import BeautifulSoup
import json
import requests

def getAlternateDesignIds(designId):
    response = requests.get(
        "https://www.bricklink.com/v2/catalog/catalogitem.page",
        params={"P": designId},
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0"}
    )
    soup = BeautifulSoup(response.text, "html.parser")
    mainBlocks = soup.find_all(id="id_divBlock_Main")
    if not mainBlocks:
        return None
    mainBlock, = mainBlocks
    itemNos = mainBlock.select(
        "table > tbody > tr > td > span > span"
    )
    if len(itemNos) == 1:
        return []

    alternateItemNo = itemNos[1]
    return json.loads("[{}]".format(alternateItemNo.text))

print(getAlternateDesignIds(3003))