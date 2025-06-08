import React from 'react';
import { Avatar, Button } from '@mui/material';
import './Header.css';
import { useNavigate } from 'react-router-dom';

const Header = () => {
  // جلب اسم المستخدم من localStorage أو القيمة الافتراضية
  const username = localStorage.getItem('username') || 'Administrateur';
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('admin_logged_in');
    navigate('/login');
  };

  return (
    <div className="header">
      <div className="header-title">
        Tableau de bord
      </div>
      <div className="header-actions">
        <div className="user-info">
          <Avatar className="user-avatar">{username.slice(0,2).toUpperCase()}</Avatar>
          <span className="user-name">{username}</span>
        </div>
        <Button variant="outlined" color="error" onClick={handleLogout} style={{marginLeft: 16}}>
          Déconnexion
        </Button>
      </div>
    </div>
  );
};

export default Header; 