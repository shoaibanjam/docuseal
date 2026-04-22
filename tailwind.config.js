module.exports = {
  content: [
    './app/javascript/**/*.{js,vue}',
    './app/views/**/*.erb'
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#0A192C',
          50: '#E9EEF5',
          100: '#CBD7E6',
          200: '#A5BBD3',
          300: '#7F9FBF',
          400: '#5B86AC',
          500: '#3A6C95',
          600: '#25547A',
          700: '#153D5F',
          800: '#0C2A46',
          900: '#0A192C'
        },
        secondary: {
          DEFAULT: '#04BE99',
          50: '#E7FCF7',
          100: '#C2F6EA',
          200: '#99F0DE',
          300: '#6FE9D1',
          400: '#46E3C4',
          500: '#04BE99',
          600: '#03987A',
          700: '#02725C',
          800: '#014D3F',
          900: '#003226'
        },
        neutral: {
          DEFAULT: '#0B1421',
          50: '#F5F8FB',
          100: '#E4EAF2',
          200: '#CFD7E2',
          300: '#B3BFCD',
          400: '#8E9AA8',
          500: '#6E7987',
          600: '#505A67',
          700: '#37404D',
          800: '#1F2733',
          900: '#0B1421'
        },
        success: '#22C55E',
        error: '#EF4444',
        warning: '#F59E0B',
        info: '#0EA5E9'
      },
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
        'ds-sm': '0 2px 8px rgba(3, 10, 24, 0.12)',
        'ds-md': '0 8px 20px rgba(3, 10, 24, 0.2)',
        'ds-lg': '0 16px 36px rgba(3, 10, 24, 0.28)',
        'ds-xl': '0 24px 56px rgba(3, 10, 24, 0.36)',
        'focus-ring': '0 0 0 3px rgba(31, 224, 179, 0.25)',
        'focus-ring-neutral': '0 0 0 3px rgba(38, 56, 84, 0.15)'
      },
      borderRadius: {
        'ds-4': '4px',
        'ds-8': '8px',
        'ds-12': '12px',
        'ds-16': '16px',
        'ds-20': '20px'
      },
      spacing: {
        18: '4.5rem',
        22: '5.5rem',
        26: '6.5rem',
        30: '7.5rem',
        34: '8.5rem'
      },
      zIndex: {
        base: '1',
        raised: '10',
        sticky: '40',
        overlay: '60',
        modal: '80',
        toast: '90',
        tooltip: '100'
      },
      opacity: {
        2: '0.02',
        4: '0.04',
        8: '0.08',
        12: '0.12',
        16: '0.16',
        24: '0.24',
        36: '0.36',
        72: '0.72'
      }
    }
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        'docuseal-dark': {
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
          '--rounded-btn': '0.625rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem',
          '--rounded-box': '1rem'
        }
      },
      {
        'docuseal-light': {
          'color-scheme': 'light',
          primary: '#0A192C',
          'primary-content': '#12233C',
          secondary: '#04BE99',
          'secondary-content': '#00382B',
          accent: '#03A786',
          'accent-content': '#ECFFFB',
          neutral: '#E4EAF2',
          'neutral-content': '#12233C',
          error: '#DC2626',
          'error-content': '#FFF5F5',
          warning: '#D97706',
          'warning-content': '#FFFBEB',
          success: '#15803D',
          'success-content': '#F0FDF4',
          'base-100': '#F5F8FB',
          'base-200': '#ECF1F7',
          'base-300': '#DDE6F0',
          'base-content': '#12233C',
          info: '#0284C7',
          'info-content': '#EFF6FF',
          '--rounded-btn': '0.625rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem',
          '--rounded-box': '1rem'
        }
      }
    ]
  }
}
