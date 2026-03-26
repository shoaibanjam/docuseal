module.exports = {
  content: [
    './app/javascript/**/*.{js,vue}',
    './app/views/**/*.erb'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif']
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out',
        'fade-in-up': 'fadeInUp 0.25s ease-out'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(4px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        }
      },
      boxShadow: {
        soft: '0 2px 8px rgba(38, 56, 84, 0.06)',
        'soft-lg': '0 4px 16px rgba(38, 56, 84, 0.08)',
        'soft-xl': '0 8px 24px rgba(38, 56, 84, 0.1)',
        'focus-ring': '0 0 0 3px rgba(31, 224, 179, 0.25)',
        'focus-ring-neutral': '0 0 0 3px rgba(38, 56, 84, 0.15)'
      }
    }
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'dark',
          primary: '#0A192C',
          'primary-content': '#d5e3fe',
          secondary: '#04BE99',
          'secondary-content': '#00382b',
          accent: '#06be99',
          'accent-content': '#FFFFFF',
          neutral: '#051427',
          'neutral-content': '#d5e3fe',
          error: '#ffb4ab',
          'error-content': '#690005',
          warning: '#ffb86b',
          'warning-content': '#1b1200',
          success: '#46ddb7',
          'success-content': '#002018',
          'base-100': '#051427',
          'base-200': '#0d1c2f',
          'base-300': '#122033',
          'base-content': '#d5e3fe',
          info: '#06be99',
          'info-content': '#FFFFFF',
          '--rounded-btn': '0.5rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem',
          '--rounded-box': '0.75rem'
        }
      }
    ]
  }
}
