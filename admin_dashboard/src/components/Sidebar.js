import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import DashboardIcon from '@mui/icons-material/Dashboard';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import PaymentIcon from '@mui/icons-material/Payment';
import HeadsetMicIcon from '@mui/icons-material/HeadsetMic';
import LogoutIcon from '@mui/icons-material/Logout';
import PeopleIcon from '@mui/icons-material/People';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import StorefrontIcon from '@mui/icons-material/Storefront';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import MenuIcon from '@mui/icons-material/Menu';
import CloseIcon from '@mui/icons-material/Close';
import { useState } from 'react';
import './Sidebar.css';
import LockOpenIcon from '@mui/icons-material/LockOpen';

const Sidebar = () => {
  const location = useLocation();
  const [open, setOpen] = useState(false);
  const isMobile = window.innerWidth <= 480;
  const navigate = useNavigate();
  
  const menuItems = [
    { path: '/', icon: <DashboardIcon />, title: 'Tableau de bord' },
    { path: '/driver-management', icon: <DirectionsCarIcon />, title: 'Gestion des chauffeurs' },
    { path: '/client-management', icon: <PeopleIcon />, title: 'Gestion des clients' },
    { path: '/provider-management', icon: <StorefrontIcon />, title: 'Gestion des fournisseurs' },
    { path: '/deliveries', icon: <LocalShippingIcon />, title: 'Livraisons' },
    { path: '/payments', icon: <PaymentIcon />, title: 'Paiements' },
    { path: '/admin-workers', icon: <AdminPanelSettingsIcon />, title: 'Administrateurs' },
    { path: '/customer-support', icon: <HeadsetMicIcon />, title: 'Support client' },
    { path: '/otp-codes', icon: <LockOpenIcon />, title: 'Codes OTP envoyés' },
  ];

  const handleLogout = (e) => {
    e.preventDefault();
    localStorage.removeItem('token');
    localStorage.removeItem('refresh');
    localStorage.removeItem('user');
    localStorage.removeItem('username');
    navigate('/login');
  };

  return (
    <>
      {isMobile && (
        <button className="sidebar-toggle-btn" onClick={() => setOpen(o => !o)}>
          {open ? <CloseIcon /> : <MenuIcon />}
        </button>
      )}
      <div className={`sidebar${isMobile && open ? ' open' : ''}`}>
        <div className="sidebar-header">
          <div className="logo-container">
            <img src={process.env.PUBLIC_URL + '/Tawssil_logo.png'} alt="Tawssil Logo" className="logo-icon" style={{ width: 72, height: 72, objectFit: 'contain' }} />
          </div>
        </div>
        <div className="sidebar-menu">
          {menuItems.map((item) => (
            <Link 
              key={item.path} 
              to={item.path} 
              className={`sidebar-item ${location.pathname === item.path ? 'active' : ''}`}
              title={item.title}
              onClick={() => isMobile && setOpen(false)}
            >
              <div className="sidebar-icon">{item.icon}</div>
            </Link>
          ))}
        </div>
        <div className="sidebar-footer">
          <a href="#logout" className="sidebar-item" title="Déconnexion" onClick={handleLogout}>
            <div className="sidebar-icon"><LogoutIcon /></div>
          </a>
        </div>
      </div>
    </>
  );
};

export default Sidebar; 