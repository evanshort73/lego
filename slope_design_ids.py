import csv
import requests

columns = ("design_id", "width", "length", "height", "slope_angle", "orientation")
partRows = {
    "1x2": (3040, 1, 2, 1, 45, "normal"),
    "2x3": (3298, 2, 3, 1, 25, "normal"),
    "1x2x3": (4460, 1, 2, 3, 73, "normal"),
    "1x3": (4286, 1, 3, 1, 25, "normal"),
    "-1x2": (3665, 1, 2, 1, 45, "inverted"),
    "steep 2x3": (3038, 2, 3, 1, 45, "normal"),
    "2x2x3": (98560, 2, 2, 3, 73, "normal"),
    "-2x2": (3660, 2, 2, 1, 45, "inverted"),
    "2x2/radar": (82024, 2, 2, 1, 45, "normal"),
    "2x2": (3039, 2, 2, 1, 45, "normal"),
    "clear 2x2": (35277, 2, 2, 1, 45, "normal"),
    "-2x3": (3747, 2, 3, 1, 25, "inverted"),
    "-1x3": (4287, 1, 3, 1, 25, "inverted"),
    "2x4": (3037, 2, 4, 1, 45, "normal"),
    "gradual 2x4": (30363, 2, 4, 1, 18, "normal"),
    "3x3": (4161, 3, 3, 1, 25, "normal"),
    "1x6x5": (30249, 1, 6, 5, 55, "normal"),
    "3x4": (3297, 3, 4, 1, 25, "normal")
}
designIdRows = {row[0]: row for row in partRows.values()}

colorNames = {
    "black": ["BLACK"],
    "white": ["WHITE"],
    "light gray": ["MED. ST-GREY"],
    "red": ["BR.RED"],
    "dark gray": ["DK. ST. GREY"],
    "yellow": ["BR.YEL"],
    "blue": ["BR.BLUE"],
    "tan": ["BRICK-YEL"],
    "brown": ["RED. BROWN"],
    "green": ["DK.GREEN", "DK. GREEN"],
    "tr clear": ["TR."],
    "tr light blue": ["TR.L.BLUE"],
    "tr red": ["TR.RED"],
    "mint": ["SAND GREEN"],
    "tr yellow": ["TR.YEL"],
    "tr blue": ["TR.BLUE"],
    "tr orange": ["TR. BR. ORANGE"],
    "dark purple": ["M. LILAC"],
    "tr bright green": ["TR.FL.GREEN"],
    "purple": ["BR. VIOLET"],
    "earth orange": ["L.ORABROWN"]
}
inventory = {
    "tan": {
        "-1x2": 2,
        "-2x2": 2,
        "1x3": 2,
        "1x2": 15
    },
    "white": {
        "-1x2": 7,
        "-2x2": 2,
        "-2x2/computer": 2,
        "1x2": 3,
        "2x2": 3,
        "2x2/radar": 1,
        "2x2/display": 1,
        "2x3/number 1": 1,
        "2x3/logo": 1,
        "1x3": 5,
        "3x4/turbo": 1,
        "2x2x3": 6
    },
    "green": {
        "-1x2": 2,
        "1x2": 1,
        "1x3": 4,
        "2x2": 6,
        "steep 2x3": 12,
        "2x3/mcdonalds": 2,
        "3x3": 4
    },
    "yellow": {
        "-1x2": 9,
        "-2x2": 13,
        "-1x3": 5,
        "-2x3": 1,
        "1x2": 12,
        "2x2": 9,
        "1x3": 2,
        "2x3": 2,
        "2x3/submarine": 1
    },
    "mint": {
        "1x2": 6
    },
    "dark purple": {
        "2x3": 1
    },
    "tr clear": {
        "clear 2x2": 7
    },
    "blue": {
        "-2x3": 1,
        "1x2": 2,
        "2x2": 12,
        "2x2/computer": 1,
        "2x3": 20,
        "2x3/logo": 1,
        "1x2x3": 2,
        "2x2x3": 4,
        "3x4": 9
    },
    "dark gray": {
        "-1x2": 10,
        "-2x2": 12,
        "-2x3": 4,
        "1x2": 11,
        "2x2": 10,
        "2x2/display": 3,
        "2x3": 4,
        "2x3/circuit": 2,
        "gradual 2x4": 1,
        "1x3": 2
    },
    #gray MB
    #"-2x2": 5,
    #"1x2": 6,
    #"2x2": 2,
    "light gray": {
        "-1x2": 5,
        "-2x2": 2,
        "-2x3": 1,
        "1x2": 3,
        "2x2": 2,
        "2x2/computer": 2,
        "1x3": 6,
        "2x4": 1,
        "1x2x3": 8,
        "2x2x3": 2,
        "1x6x5": 4
    },
    "black": {
        "-1x2": 11,
        "-2x2": 11,
        "-1x3": 4,
        "-2x3": 8,
        "1x2": 32,
        "2x2": 8,
        "1x3": 5,
        "2x3": 19,
        "2x3/submarine": 6,
        "2x3/space police": 2,
        "2x3/number 4": 2,
        "steep 2x3": 2,
        "2x4": 6,
        "3x4": 2,
        "1x2x3": 4
    },
    "red": {
        "-1x2": 4,
        "-2x2": 14,
        "-2x3": 8,
        "1x2": 8,
        "1x3": 5,
        "2x2": 28,
        "2x3": 22,
        "2x3/number 28": 2,
        "2x3/mcdonalds": 1,
        "steep 2x3": 2,
        "2x4": 62,
        "3x4": 25,
        "3x4/fire engine": 1,
        "3x4/blue triangles": 1,
    }
}

knownMissing = {
    (3038, "green"),
    (4161, "green")
}

def getColorMap(designId, colorPatterns):
    response = requests.get(
        "https://www.lego.com/en-US/service/rpservice/getitemordesign",
        params={"itemordesignnumber": designId, "issalesflow": "false"},
        cookies={"csAgeAndCountry": '{"age":"25","countrycode":"US"}'}
    )

    bricks = response.json()["Bricks"]

    designIds = {
        brick["DesignId"] for brick in bricks
    }
    if designIds != {designId}:
        raise AssertionError(designIds, designId)

    description = ",".join(sorted({
        brick["ItemDescr"] for brick in bricks
    }))
    category = ",".join(sorted({
        brick["MaingroupDescr"] for brick in bricks
    }))
    colorElementIds = {
        brick["ColourDescr"]: (brick["ItemNo"], brick["Asset"]) \
            for brick in bricks
    }
    colorData = {}
    for color, patternCounts in colorPatterns.items():
        for name in colorNames[color]:
            try:
                elementId, asset = colorElementIds[name]
                if asset != "/bricks/5/2/{}".format(elementId):
                    raise AssertionError(elementId, asset)
                break
            except KeyError:
                pass
        else:
            if (designId, color) in knownMissing:
                elementId = ""
            else:
                raise KeyError(designId, description, colorNames[color])
        colorData[color] = (elementId, patternCounts)
    return description, category, colorData

designIdColors = {}
for color, partCounts in inventory.items():
    for part, count in partCounts.items():
        try:
            row = partRows[part]
        except KeyError as e:
            try:
                part, pattern = part.split("/", maxsplit=1)
            except ValueError:
                raise e
            row = partRows[part]
        else:
            try:
                part, pattern = part.split("/", maxsplit=1)
            except ValueError:
                pattern = ""
        designId = row[0]
        colorPatterns = designIdColors.setdefault(designId, {})
        patternCounts = colorPatterns.setdefault(color, {})
        patternCounts[pattern] = count

class CSVWriter: # pylint: disable=undefined-variable
    def __init__(self, f):
        self.writer = csv.writer(f)
        self.columns = None
    def write(self, *args):
        columns, values = zip(*args)
        if self.columns is None:
            self.writer.writerow(columns)
            self.columns = columns
        elif self.columns != columns:
            raise AssertionError(self.columns, columns)
        self.writer.writerow(values)


with open("slopes.csv", "w", newline="", encoding="utf-8") as f:
    writer = CSVWriter(f)
    for designId, colorPatterns in sorted(designIdColors.items()):
        description, category, colorData = \
            getColorMap(designId, colorPatterns)
        for color, (elementId, patternCounts) in sorted(
            colorData.items()
        ):
            for pattern, count in sorted(patternCounts.items()):
                writer.write(
                    *zip(columns, designIdRows[designId]),
                    ("description", description),
                    ("category", category),
                    ("element_id", str(elementId)),
                    ("color", color),
                    ("print", pattern),
                    ("amount", count)
                )
