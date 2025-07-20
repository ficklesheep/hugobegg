const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const { marked } = require('marked');

const postsDir = path.join(__dirname, '..', 'content', 'blog');
const outputPath = path.join(__dirname, '..', 'public', 'posts.json');

function getAllMarkdownFiles(dir) {
  let files = [];
  if (!fs.existsSync(dir)) {
    console.error(`Directory does not exist: ${dir}`);
    return files;
  }
  const items = fs.readdirSync(dir, { withFileTypes: true });

  items.forEach(item => {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      files = files.concat(getAllMarkdownFiles(fullPath));
    } else if (item.isFile() && fullPath.endsWith('.md')) {
      files.push(fullPath);
    }
  });

  return files;
}

const files = getAllMarkdownFiles(postsDir);
if (files.length === 0) {
  console.warn('No markdown files found.');
}

const posts = files.map(filePath => {
  const fileContents = fs.readFileSync(filePath, 'utf8');
  const parsed = matter(fileContents);
  const { data, content } = parsed;

  // ✅ Update image path if it exists
  if (data.image) {
    const filename = path.basename(data.image);
    const correctPath = `/static/bloguploads/${filename}`;
    if (data.image !== correctPath) {
      console.log(`Updating image path in ${filePath}`);
      data.image = correctPath;

      const updatedMarkdown = matter.stringify(content, data);
      fs.writeFileSync(filePath, updatedMarkdown, 'utf8');
    }
  }

  return {
    title: data.title || 'Untitled',
    date: data.date || null,
    image: data.image || null,
    content: marked(content),
    slug: path.relative(postsDir, filePath).replace(/\\/g, '/').replace(/\.md$/, ''),
  };
});

// Ensure output directory exists
const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

fs.writeFileSync(outputPath, JSON.stringify(posts, null, 2));
console.log(`✅ Built ${posts.length} posts to ${outputPath}`);
