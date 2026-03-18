module.exports = {
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
          'color-scheme': 'light',
          // Brand palette (dark theme)
          primary: '#0a1628',
          'primary-content': '#E5E7EB',
          secondary: '#00d5a4',
          'secondary-content': '#021018',
          accent: '#00b48a',
          'accent-content': '#FFFFFF',
          neutral: '#020617',
          'neutral-content': '#E5E7EB',
          // Surface colors
          'base-100': '#020617', // main app background
          'base-200': '#020617',
          'base-300': '#111827',
          'base-content': '#E5E7EB',
          info: '#00b0ff',
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
