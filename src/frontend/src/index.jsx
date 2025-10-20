import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

import './setup/i18n';
import './setup/icons';
import './setup/sentry';


const container = document.getElementById('app-root');

if (container) {
  const root = ReactDOM.createRoot(container);
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
} else {
  console.warn('app-root element not found');
}
