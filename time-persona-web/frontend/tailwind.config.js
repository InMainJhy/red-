/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        mint: {
          50: '#f0fdfa', 100: '#ccfbf1', 200: '#99f6e4', 300: '#5eead4',
          400: '#2dd4bf', 500: '#14b8a6', 600: '#0d9488', 700: '#0f766e',
          DEFAULT: '#4ECDC4', dark: '#0d9488', light: '#99f6e4',
          pale: '#f0fdfa', bg: '#ccfbf1',
        },
        lavender: {
          50: '#faf5ff', 100: '#ede9fe', 200: '#ddd6fe', 300: '#c4b5fd',
          400: '#a78bfa', 500: '#8b5cf6', 600: '#7c3aed',
          DEFAULT: '#b8a9d9', dark: '#7c3aed', light: '#ddd6fe', pale: '#f5f3ff',
        },
        card: '#ffffff',
        background: '#f8fafc',
      },
      borderRadius: {
        'xxl': '16px', 'xxl2': '20px', 'xxl3': '24px', 'pill': '9999px',
      },
    },
  },
  plugins: [],
}
