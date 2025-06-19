import React from 'react';
import { Avatar } from '@mui/material';
import './Header.css';

const Header = () => {
  // جلب اسم المستخدم من localStorage أو القيمة الافتراضية
  const username = localStorage.getItem('username') || 'Administrateur';

  return (
    <div className="header">
      <div className="header-title">
        Tableau de bord
      </div>
      <div className="header-actions">
        <div className="user-info-professional">
          <Avatar className="user-avatar-large">{username.slice(0,2).toUpperCase()}</Avatar>
          <div className="user-details">
            <span className="user-name-professional">{username}</span>
            <span className="user-welcome">Bienvenue !</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Header; 