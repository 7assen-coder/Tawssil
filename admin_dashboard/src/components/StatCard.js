import React from 'react';
import './StatCard.css';

const StatCard = ({ title, value, icon, change, colorClass }) => {
  const isPositive = change && change.startsWith('+');
  
  return (
    <div className={`stat-card card ${colorClass || ''}`}>
      <div className={`stat-icon ${colorClass || ''}`}>
        {icon}
      </div>
      <div className="stat-details">
        <h3 className="stat-title">{title}</h3>
        <div className="stat-value">{value}</div>
        {change && (
          <div className={`stat-change ${isPositive ? 'positive-change' : 'negative-change'}`}>
            {change} {parseInt(change) === 0 ? 'par rapport au mois dernier (stable)' : 'par rapport au mois dernier'}
          </div>
        )}
      </div>
    </div>
  );
};

export default StatCard; 