import React from 'react';
import * as Sentry from "@sentry/react";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faRocket } from '@fortawesome/free-solid-svg-icons';


function App() {
  return (
    <Sentry.ErrorBoundary>
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        fontFamily: 'Arial, sans-serif'
      }}>
        <div style={{ textAlign: 'center' }}>
          <h1>
            <FontAwesomeIcon icon={faRocket} /> Hello Dev World!
          </h1>
          <p>React + Vite + Django + Sentry + FontAwesome is working!</p>
        </div>
      </div>
    </Sentry.ErrorBoundary>
  );
}

export default App;