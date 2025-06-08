import React from 'react';
import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import DriverManagement from './pages/DriverManagement';
import ClientManagement from './pages/ClientManagement';
import ProviderManagement from './pages/ProviderManagement';
import Deliveries from './pages/Deliveries';
import Payments from './pages/Payments';
import Budget from './pages/Budget';
import CustomerSupport from './pages/CustomerSupport';
import Layout from './components/Layout';
import Login from './pages/Login';
import AdminWorkers from './pages/AdminWorkers';
import OtpCodes from './pages/OtpCodes';
import './App.css';
import './styles/responsive.css';

// مكون حماية المسارات مع تحقق من صلاحية التوكن
function PrivateRoute() {
  const [isValid, setIsValid] = React.useState(null);
  React.useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      setIsValid(false);
      return;
    }
    fetch('http://localhost:8000/api/validate-token/', {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then(res => {
        if (res.ok) {
          setIsValid(true);
        } else {
          localStorage.removeItem('token');
          setIsValid(false);
        }
      })
      .catch(() => {
        localStorage.removeItem('token');
        setIsValid(false);
      });
  }, []);
  if (isValid === null) return null; // يمكن وضع سبينر هنا
  return isValid ? <Outlet /> : <Navigate to="/login" replace />;
}

function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<PrivateRoute />}> {/* حماية جميع المسارات */}
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="driver-management" element={<DriverManagement />} />
          <Route path="client-management" element={<ClientManagement />} />
          <Route path="provider-management" element={<ProviderManagement />} />
          <Route path="deliveries" element={<Deliveries />} />
          <Route path="payments" element={<Payments />} />
          <Route path="budget" element={<Budget />} />
          <Route path="customer-support" element={<CustomerSupport />} />
          <Route path="admin-workers" element={<AdminWorkers />} />
          <Route path="otp-codes" element={<OtpCodes />} />
        </Route>
      </Route>
    </Routes>
  );
}

export default App;
