const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const { marked } = require('marked');

// Define the path to the blog content directory
const postsDir = path.join(__dirname, '..', 'content', 'blog');

// Define the output path for the generated JSON file
const outputPath = path.join(__dirname, '..', 'public', 'posts.json');

// Function to recursively get all Markdown files in the specified directory
function getAllMarkdownFiles(dir) {
  let files = [];
  const items = fs.readdirSync(dir, { withFileTypes: true });

  items.forEach(item => {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      files = files.concat(getAllMarkdownFiles(fullPath)); // Recursively add files from subdirectories
    } else if (item.isFile() && fullPath.endsWith('.md')) {
      files.push(fullPath); // Add Markdown files to the list
    }
  });

  return files;
}

// Get all Markdown files from the blog content directory
const files = getAllMarkdownFiles(postsDir);

// Process each Markdown file to extract metadata and content
const posts = files.map(filePath => {
  const fileContents = fs.readFileSync(filePath, 'utf8');
  const { data, content } = matter(fileContents);

  return {
    title: data.title || 'Untitled', // Use 'Untitled' if no title is provided
    date: data.date || null, // Use null if no date is provided
    content: marked(content), // Convert Markdown content to HTML
    slug: path.relative(postsDir, filePath)
      .replace(/\\/g, '/') // Normalize path separators
      .replace(/\.md$/, ''), // Remove the '.md' extension
  };
});

// Ensure the 'public' directory exists before writing the JSON file
fs.mkdirSync(path.dirname(outputPath), { recursive: true });

// Write the processed posts to the 'posts.json' file
fs.writeFileSync(outputPath, JSON.stringify(posts, null, 2));

console.log(`Built ${posts.length} posts to ${outputPath}`);
