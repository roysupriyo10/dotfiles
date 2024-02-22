#!/usr/bin/env node

import fs from "fs";
import { readdir, readFile } from "fs/promises";
import { resolve } from "path";

const BASE_PATH =
  process.argv[2] || "/home/roysupriyo10/Developer/pitch40/server";

const excludeDirs = ["node_modules", ".git", "dist"];
const excludeFiles = [
  ".gitignore",
  ".env",
  "firebase-env.json",
  ".env.example",
];

const isLineComment = (line: string) => {
  for (let i = 0; i < line.length; i++) {
    const character = line[i];

    if (character === " ") {
      continue;
    }

    if (character !== "/") {
      return false;
    }

    if (line[i + 1] === "/") {
      return true;
    }
  }
};

let results: {
  fileName: string;
  code: number;
  lines: number;
  comments: number;
  blank: number;
}[] = [];

let maxLength = 0;
const searchDirents = async (parentDirectory: string, dirents: fs.Dirent[]) => {
  for (let i = 0; i < dirents.length; i++) {
    const dirent = dirents[i];
    const childPath = resolve(parentDirectory, dirent.name);
    if (
      dirent.isFile() &&
      (excludeFiles.includes(dirent.name) ||
        (!dirent.name.endsWith(".ts") && !dirent.name.endsWith(".tsx") && !dirent.name.endsWith(".dart")))
    )
      continue;

    if (dirent.isDirectory()) {
      if (excludeDirs.includes(dirent.name)) {
        continue;
      }

      await readDirectory(childPath);
      continue;
    }

    const fileContent = (await readFile(childPath)).toString();

    const lines = fileContent.split("\n");
    let blankLines = 0;
    let comments = 0;
    let codeLineCount = 0;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      const isComment = isLineComment(line);
      const isBlank = line.length === 0;

      if (isComment) comments++;
      if (isBlank) blankLines++;
      if (!isBlank && !isComment) codeLineCount++;
    }
    const fileName = childPath.split("/")[childPath.split("/").length - 1];

    results.push({
      fileName,
      comments,
      lines: lines.length - 1,
      blank: blankLines,
      code: codeLineCount,
    });
    if (lines.length > 100) {
      if (fileName.length > maxLength) {
        maxLength = fileName.length;
      }
      // lines.length > 100 &&
      //   console.log(
      //     "\x1b[33m%s\x1b[0m",
      //     childPath
      //       .split("/")
      //       [
      //         childPath.split("/").length - 1
      //       ].concat(new Array(maxLength - fileName.length + 1).join(" ")),
      //     "all:",
      //     lines.length - 1,
      //     "blank:",
      //     blankLines,
      //     "comments:",
      //     comments,
      //     "code:",
      //     codeLineCount,
      //   );
    }
  }
};

// Define a function to read all .ts files from a directory recursively

const readDirectory = async (path: string) => {
  try {
    const directory = await readdir(path, { withFileTypes: true });

    await searchDirents(path, directory);
  } catch (error) {
    console.error(error);
  }
};

(async () => {
  await readDirectory(BASE_PATH);
  results.forEach((result) => {
    if (result.lines < 100) return;
    console.log(
      "\x1b[33m%s\x1b[0m",
      result.fileName.concat(
        new Array(maxLength - result.fileName.length + 1).join(" "),
      ),
      "all:",
      result.lines,
      "blank:",
      result.blank,
      "comments:",
      result.comments,
      "code:",
      result.code,
      // "\n",
    );
  });

  const stats = results.reduce<{
    all: number;
    code: number;
    comments: number;
    blank: number;
  }>(
    (state, result) => {
      state["comments"] = state["comments"] + result.comments;
      state["blank"] = state["blank"] + result.blank;
      state["code"] = state["code"] + result.code;
      state["all"] = state["all"] + result.lines;

      return state;
    },
    {
      comments: 0,
      code: 0,
      all: 0,
      blank: 0,
    },
  );

  console.log(
    new Array(maxLength + 1).join(" "),
      "files:",
      results.length,
    "all:",
    stats.all,
    "blank:",
    stats.blank,
    "comments:",
    stats.comments,
    "code:",
    stats.code,
  );
})();
