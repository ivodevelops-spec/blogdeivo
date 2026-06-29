module.exports = function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy("src/static");
  eleventyConfig.addPassthroughCopy({ "src/admin/config.yml": "admin/config.yml" });

  eleventyConfig.addCollection("allPosts", function (collectionApi) {
    return [...collectionApi.getFilteredByGlob("src/posts/*.md"), ...collectionApi.getFilteredByGlob("src/micro/*.md")]
      .sort((a, b) => b.date - a.date);
  });

  eleventyConfig.addFilter("fecha", function (date) {
    const d = new Date(date);
    const meses = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    return `${d.getDate()} ${meses[d.getMonth()]} ${d.getFullYear()}`;
  });

  eleventyConfig.addFilter("iso", function (date) {
    return new Date(date).toISOString().split("T")[0];
  });

  eleventyConfig.addCollection("categories", function (collectionApi) {
    const cats = new Set();
    collectionApi.getAll().forEach(item => {
      const c = item.data.categories;
      if (Array.isArray(c)) c.forEach(x => cats.add(x));
    });
    return [...cats].sort();
  });

  return {
    dir: { input: "src", output: "_site", includes: "_includes" },
    markdownTemplateEngine: "njk",
  };
};
