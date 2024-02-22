const fs = require('fs');
const path = require('path');
const { parse } = require('@typescript-eslint/parser');

const BASE_PATH = "/home/roysupriyo10/Developer/pitch40/server"; // Update with the path to your NestJS codebase
const LARGE_FUNCTION_THRESHOLD = 50; // Number of lines that defines a "large" function

function readDirectory(directory) {
  fs.readdir(directory, { withFileTypes: true }, (err, dirents) => {
    if (err) {
      console.error('Error reading directory:', directory, err);
      return;
    }
    dirents.forEach((dirent) => {
      const fullPath = path.join(directory, dirent.name);
      if (dirent.isDirectory()) {
        if (!['node_modules', 'dist'].includes(dirent.name)) {
          readDirectory(fullPath); // Recurse into subdirectories, excluding node_modules and dist
        }
      } else if (dirent.name.endsWith('.ts')) {
        analyzeFile(fullPath); // Analyze TypeScript files
      }
    });
  });
}

function analyzeFile(filePath) {
  fs.readFile(filePath, 'utf8', (err, content) => {
    if (err) {
      console.error('Error reading file:', filePath, err);
      return;
    }
    try {
      const ast = parse(content, {
        sourceType: 'module',
        ecmaFeatures: {
          jsx: false,
        },
      });
      findLargeFunctions(ast, filePath);
    } catch (parseError) {
      console.error('Error parsing file:', filePath, parseError);
    }
  });
}

function findLargeFunctions(ast, filePath) {
  const nodes = extractFunctions(ast.body);
  nodes.forEach(node => {
    const lines = node.loc.end.line - node.loc.start.line;
    if (lines > LARGE_FUNCTION_THRESHOLD) {
      console.log(`Large function in ${filePath}: ${node.id ? node.id.name : 'anonymous'} (${node.loc.start.line}-${node.loc.end.line})`);
    }
  });
}

function extractFunctions(nodes, collectedNodes = []) {
  nodes.forEach(node => {
    if (node.type === 'FunctionDeclaration' || node.type === 'FunctionExpression' || node.type === 'ArrowFunctionExpression') {
      collectedNodes.push(node);
    } else if (node.type === 'MethodDefinition') {
      collectedNodes.push(node.value);
    } else if (node.type === 'ExportNamedDeclaration' && node.declaration) {
      extractFunctions([node.declaration], collectedNodes);
    } else if (node.type === 'ExportDefaultDeclaration' && node.declaration) {
      extractFunctions([node.declaration], collectedNodes);
    } else if (node.type === 'BlockStatement') {
      extractFunctions(node.body, collectedNodes);
    } else if (node.type === 'ClassBody') {
      extractFunctions(node.body, collectedNodes);
    }
    
    // Add more cases here if other kinds of nodes can contain functions/methods.
  });
  return collectedNodes;
}

readDirectory(BASE_PATH);

// const fs = require("fs");
// const path = require("path");
// const { parse } = require("@typescript-eslint/parser");
//
// const BASE_PATH = "/home/roysupriyo10/Developer/pitch40/server"; // Set the path to your NestJS codebase
// const LARGE_FUNCTION_THRESHOLD = 50; // Threshold for number of lines in a function
//
// function readDirectory(directory) {
//   fs.readdir(directory, { withFileTypes: true }, (err, dirents) => {
//     // console.log(dirents);
//     if (err) {
//       // console.error("Error reading directory:", err);
//       return;
//     }
//
//     933;
//
//     dirents.forEach((dirent) => {
//       const fullPath = path.join(directory, dirent.name);
//       if (dirent.isFile() && !dirent.name.endsWith(".ts")) return;
//       if (dirent.isDirectory()) {
//         if (dirent.name === "node_modules" || dirent.name === "dist") return;
//         readDirectory(fullPath); // Recurse into subdirectories
//       } else if (dirent.isFile() && dirent.name.endsWith(".ts")) {
//         analyzeFile(fullPath); // Analyze TypeScript files
//       }
//     });
//   });
// }
//
// function analyzeFile(filePath) {
//   fs.readFile(filePath, "utf8", (err, content) => {
//     if (err) {
//       // console.error(`Error reading file ${filePath}:`, err);
//       return;
//     }
//
//     try {
//       const ast = parse(content, {
//         sourceType: "module",
//         ecmaVersion: 2020,
//         ecmaFeatures: {
//           jsx: false, // Set to true if you want to support JSX
//         },
//       });
//
//       findLargeFunctions(ast, filePath);
//     } catch (error) {
//       console.error(error);
//     }
//   });
// }
//
// function findLargeFunctions(ast, filePath) {
//   const nodes = [];
//   extractFunctions(ast, nodes);
//
//   nodes.forEach((node) => {
//     const lines = node.loc.end.line - node.loc.start.line;
//     if (lines > LARGE_FUNCTION_THRESHOLD) {
//       console.log(
//         `Large function found in ${filePath} at lines ${node.loc.start.line}-${node.loc.end.line}`,
//       );
//     }
//   });
// }
//
// // Recursively extract function nodes from AST
// function extractFunctions(node, nodes) {
//   if (!node) return;
//
//   const functionTypes = [
//     "FunctionDeclaration",
//     "FunctionExpression",
//     "ArrowFunctionExpression",
//   ];
//
//   if (node.type === "MethodDefinition" && node.value) {
//     // Methods in classes
//     extractFunctions(node.value, nodes);
//   } else if (functionTypes.includes(node.type)) {
//     // Regular functions and arrow functions
//     nodes.push(node);
//   }
//
//   for (const key in node) {
//     if (node.hasOwnProperty(key)) {
//       const child = node[key];
//       if (typeof child === "object" && child !== null) {
//         extractFunctions(child, nodes);
//       }
//     }
//   }
// }
//
// readDirectory(BASE_PATH);
