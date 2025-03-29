import * as fs from 'node:fs';
import * as path from 'node:path';
import { glob } from 'glob';

// mdcファイルとmdディレクトリの対応関係の定義
const mdcConfigurations = [
  {
    output: ".cursor/rules/000_general.mdc",
    sourceDir: ".cursor/rules/general",
    header: "",
    //header: "---\ndescription: プロジェクトにおける一般ルールを定義します。参照必須\nglobs: *\nalwaysApply: true\n---\n\n", // ヘッダーを追加
    filePattern: "*.md",
    sortBy: "name"
  },
  {
    output: ".cursor/rules/001_bestPractices_common.mdc",
    sourceDir: ".cursor/rules/common",
    header: "",
    //header: "---\ndescription: プロジェクトにおけるコーディングスタイルを定義します。参照必須\nglobs: *\nalwaysApply: true\n---\n\n", // ヘッダーを追加
    filePattern: "*.md",
    sortBy: "name"
  }
];

// ファイル名から数字プレフィックスを抽出してソートするための関数
function extractNumberPrefix(filename: string): number {
  const match = filename.match(/^(\d+)_/);
  return match ? parseInt(match[1], 10) : Infinity;
}

// ディレクトリの存在確認を行う関数
async function checkDirectory(dir: string): Promise<boolean> {
  try {
    await fs.promises.access(dir, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

// ディレクトリを作成する関数
async function ensureDirectory(dir: string) {
  try {
    await fs.promises.mkdir(dir, { recursive: true });
    console.log(`Created directory: ${dir}`);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'EEXIST') {
      throw error;
    }
  }
}

// mdファイルを検索して結合する関数
async function buildMdcFile(config: typeof mdcConfigurations[0]) {
  // ルートディレクトリの取得（スクリプトの実行場所から相対パスで計算）
  const rootDir = path.resolve(process.cwd());
  console.log('Root directory:', rootDir);
  
  // ソースディレクトリの完全パスを取得
  const sourceDir = path.join(rootDir, config.sourceDir);
  console.log('Source directory:', sourceDir);
  
  // ソースディレクトリを作成
  await ensureDirectory(sourceDir);
  
  // mdファイルのパターンを作成
  const pattern = path.join(sourceDir, config.filePattern);
  console.log('Search pattern:', pattern);
  
  // mdファイルを検索
  const files = await glob(pattern);
  console.log('Found files:', files);
  
  if (files.length === 0) {
    console.warn(`No files found matching pattern: ${pattern}`);
    // サンプルのMDファイルを作成
    const sampleFile = path.join(sourceDir, '001_sample.md');
    const sampleContent = `## Sample Rule\n\nThis is a sample rule file.\n\n### Purpose\n- To demonstrate the format\n- To provide an example\n\n### Guidelines\n1. Follow this format\n2. Add meaningful content\n3. Use proper markdown syntax`;
    await fs.promises.writeFile(sampleFile, sampleContent);
    console.log(`Created sample file: ${sampleFile}`);
    files.push(sampleFile);
  }
  
  // ファイル名でソート
  files.sort((a: string, b: string) => {
    const numA = extractNumberPrefix(path.basename(a));
    const numB = extractNumberPrefix(path.basename(b));
    return numA - numB;
  });
  
  // コンテンツの初期化
  let content = '';
  
  // ヘッダー情報を追加
  content += config.header;
  
  // 各mdファイルの内容を結合
  for (const file of files) {
    console.log(`Processing file: ${file}`);
    try {
      const fileContent = await fs.promises.readFile(file, 'utf8');
      content += fileContent + '\n\n';
    } catch (error) {
      console.error(`Error reading file ${file}:`, error);
      throw error;
    }
  }
  
  // mdcファイルを出力
  const outputPath = path.join(rootDir, config.output);
  console.log('Output path:', outputPath);
  
  // 出力ディレクトリが存在することを確認
  const outputDir = path.dirname(outputPath);
  await ensureDirectory(outputDir);
  
  // ファイルに書き込み
  try {
    await fs.promises.writeFile(outputPath, content);
    console.log(`Successfully wrote to ${outputPath}`);
  } catch (error) {
    console.error(`Error writing to ${outputPath}:`, error);
    throw error;
  }
  
  console.log(`Generated ${config.output} from ${files.length} files in ${config.sourceDir}`);
}

// 既存のMDCファイルの中身を空にする関数
async function cleanMdcFiles() {
  const rootDir = path.resolve(process.cwd());
  console.log('Cleaning MDC files in root directory:', rootDir);
  
  // .cursor/rules ディレクトリの存在確認と作成
  const rulesDir = path.join(rootDir, '.cursor/rules');
  console.log('Rules directory:', rulesDir);
  await ensureDirectory(rulesDir);
  
  // .mdc ファイルを検索して中身を空にする
  const mdcFiles = await glob(path.join(rulesDir, '*.mdc'));
  console.log('Found MDC files:', mdcFiles);
  
  for (const file of mdcFiles) {
    try {
      console.log(`Clearing content of MDC file: ${file}`);
      await fs.promises.writeFile(file, ''); // ファイルの中身を空にする
    } catch (error) {
      console.error(`Error clearing MDC file ${file}:`, error);
      throw error;
    }
  }
}

// メイン処理
async function main() {
  try {
    console.log('Starting MDC file generation...');
    
    // 既存のMDCファイルを削除
    await cleanMdcFiles();
    
    // 各設定に対してmdcファイルを生成
    for (const config of mdcConfigurations) {
      console.log(`\nProcessing configuration:`, config);
      await buildMdcFile(config);
    }
    console.log('\nAll mdc files have been successfully generated!');
  } catch (error) {
    console.error('Error generating mdc files:', error);
    process.exit(1);
  }
}

// スクリプトの実行
main();
