import axios from 'axios';

// إعداد إعدادات Axios الافتراضية
const api = axios.create({
  baseURL: 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// إضافة اعتراض للطلبات لإضافة رمز المصادقة
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// طلبات لوحة التحكم الرئيسية
export const getDashboardStats = () => {
  return api.get('/dashboard/stats');
};

// طلبات إدارة السائقين
export const getPendingDrivers = () => {
  return api.get('/drivers/pending');
};

export const approveDriver = (driverId) => {
  return api.post(`/drivers/${driverId}/approve`);
};

export const rejectDriver = (driverId, reason) => {
  return api.post(`/drivers/${driverId}/reject`, { reason });
};

// طلبات التوصيلات
export const getDeliveries = (status) => {
  return api.get('/deliveries', { params: { status } });
};

// طلبات المدفوعات
export const getPayments = () => {
  return api.get('/payments');
};

// طلبات تذاكر الدعم
export const getSupportTickets = () => {
  return api.get('/support/tickets');
};

export default api; 