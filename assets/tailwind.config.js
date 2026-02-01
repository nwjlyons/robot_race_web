module.exports = {
  content: [
    "./js/**/*.ts",
    "../lib/**/*.ex",
    "../lib/**/*.heex"
  ],
  theme: {
    extend: {
      colors: {
        "retro-black": "#010a01",
        "retro-gray": "#d3d3d3",
        "retro-dark-gray": "rgb(118, 118, 118)",
        "retro-green": "#00ffaa",
        "retro-red": "rgb(239, 25, 77)"
      },
      fontFamily: {
        mono: ["\"Press Start 2P\"", "monospace"]
      }
    }
  },
  plugins: []
};
