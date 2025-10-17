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

          <img src="https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExZTB5eWFyMTF6b2RibDBhd2IwMm
            llODBwdzRjMWI2OG84ZWl4bHhtdiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l3q2zVr6cu95nF6O4/giphy.gif"/>
        </div>
      </div>
    </Sentry.ErrorBoundary>
  );
}

export default App;