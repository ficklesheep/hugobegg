// scripts/build-posts.js
const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const { marked } = require('marked');


const postsDir = path.join(__dirname, '..', 'posts');
const outputFile = path.join(__dirname, '..', 'posts.json');

const files = fs.readdirSync(postsDir);

const posts = files.map(filename => {
  const filePath = path.join(postsDir, filename);
  const file = fs.readFileSync(filePath, 'utf-8');
  const { data, content } = matter(file);

  return {
    title: data.title,
    date: data.date,
    slug: filename.replace(/\.md$/, ''),
    content: marked(content)
  };
});

posts.sort((a, b) => new Date(b.date) - new Date(a.date));

fs.writeFileSync(outputFile, JSON.stringify(posts, null, 2));
console.log(`✅ Built ${posts.length} posts to posts.json`);
