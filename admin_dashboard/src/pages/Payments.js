import React, { useState, useEffect, useCallback } from 'react';
import { 
  Grid, Card, CardContent, Typography, Table, TableBody, 
  TableCell, TableContainer, TableHead, TableRow, Paper, 
  Chip, TextField, Select, MenuItem, FormControl, InputLabel,
  IconButton, Box, Tab, Tabs, Button
} from '@mui/material';
import PaidIcon from '@mui/icons-material/Paid';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import CreditCardIcon from '@mui/icons-material/CreditCard';
import MoneyIcon from '@mui/icons-material/Money';
import SearchIcon from '@mui/icons-material/Search';
import VisibilityIcon from '@mui/icons-material/Visibility';
import ReceiptIcon from '@mui/icons-material/Receipt';
import InsightsIcon from '@mui/icons-material/Insights';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import CloseIcon from '@mui/icons-material/Close';
import { XAxis, YAxis, Tooltip, Legend, ResponsiveContainer, LineChart, Line, CartesianGrid } from 'recharts';
import './Payments.css';

const Payments = () => {
  const [payments, setPayments] = useState([]);
  const [filteredPayments, setFilteredPayments] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [methodFilter, setMethodFilter] = useState('all');
  const [tabValue, setTabValue] = useState(0);
  const [period, setPeriod] = useState('week');
  const [stats, setStats] = useState({ total: 0, confirmes: 0, attente: 0, montant: 0 });
  const [openDetails, setOpenDetails] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [statusData, setStatusData] = useState([]);

  useEffect(() => {
    setIsLoading(true);
    fetch('http://localhost:8000/api/paiements/list/')
      .then(res => res.json())
      .then(data => {
        setPayments(data);
        setFilteredPayments(data);
      })
      .finally(() => setIsLoading(false));
  }, []);

  const filterPayments = useCallback(() => {
    let filtered = [...payments];
    
    // فلترة حسب التاب المحدد
    // هنا يمكن إضافة منطق إضافي للفلترة حسب التاب

    // فلترة حسب البحث
    if (searchTerm) {
      filtered = filtered.filter(payment => 
        payment.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        payment.orderId.toLowerCase().includes(searchTerm.toLowerCase()) ||
        payment.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        payment.reference.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    
    // فلترة حسب الحالة
    if (statusFilter !== 'all') {
      filtered = filtered.filter(payment => payment.status === statusFilter);
    }
    
    // فلترة حسب طريقة الدفع
    if (methodFilter !== 'all') {
      filtered = filtered.filter(payment => payment.method === methodFilter);
    }
    
    setFilteredPayments(filtered);
  // eslint-disable-next-line
  }, [payments, searchTerm, statusFilter, methodFilter]);

  useEffect(() => {
    filterPayments();
  }, [searchTerm, statusFilter, methodFilter, payments, filterPayments]);

  // جلب بيانات الإحصائيات من الباكند
  useEffect(() => {
    fetch('http://localhost:8000/api/paiements/stats/')
      .then(res => res.json())
      .then(data => {
        setStats(data);
      });
  }, []);

  // جلب بيانات المقارنة عند تغيير التاب أو الفترة
  useEffect(() => {
    if (tabValue === 1) {
      fetch(`http://localhost:8000/api/paiements/status-comparaison/?period=${period}`)
        .then(res => res.json())
        .then(data => setStatusData(data));
    }
  }, [tabValue, period]);

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
  };

  const getStatusChip = (status) => {
    switch (status) {
      case 'Confirme':
        return <Chip label="Confirmé" color="success" size="small" />;
      case 'En Attente':
        return <Chip label="En attente" color="warning" size="small" />;
      case 'Echoue':
        return <Chip label="Échoué" color="error" size="small" />;
      default:
        return <Chip label={status} size="small" />;
    }
  };

  const getMethodIcon = (method) => {
    switch (method) {
      case 'Cash':
        return <MoneyIcon className="method-icon cash" />;
      case 'App':
        return <CreditCardIcon className="method-icon app" />;
      default:
        return null;
    }
  };

  const getMethodName = (method) => {
    switch (method) {
      case 'Cash':
        return 'Espèces';
      case 'App':
        return 'Application';
      case 'Espum':
        return 'Espèces';
      default:
        return method;
    }
  };

  // أضف دالة لتغيير حالة الدفع
  const handlePaymentStatus = async (paymentId, newStatus) => {
    try {
      const response = await fetch(`http://localhost:8000/api/paiements/${paymentId}/update/`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ statut: newStatus })
      });
      if (response.ok) {
        setPayments(prev => prev.map(p => p.id === paymentId ? { ...p, status: newStatus } : p));
        setFilteredPayments(prev => prev.map(p => p.id === paymentId ? { ...p, status: newStatus } : p));
      }
    } catch (e) { /* يمكن إضافة تنبيه للخطأ */ }
  };

  const handleDetailsClick = (payment) => {
    setSelectedPayment(payment);
    setOpenDetails(true);
  };

  // احسب تاريخ البداية والنهاية للفترة المختارة
  const getPeriodRange = () => {
    const now = new Date();
    let start, end;
    if (period === 'day') {
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      end = new Date(start);
      end.setHours(23,59,59,999);
    } else if (period === 'week') {
      const day = now.getDay();
      const diffToMonday = (day === 0 ? -6 : 1) - day;
      start = new Date(now);
      start.setDate(now.getDate() + diffToMonday);
      start.setHours(0,0,0,0);
      end = new Date(start);
      end.setDate(start.getDate() + 6);
      end.setHours(23,59,59,999);
    } else if (period === 'month') {
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      end.setHours(23,59,59,999);
    }
    return {
      start: start.toLocaleDateString('fr-FR'),
      end: end.toLocaleDateString('fr-FR')
    };
  };
  const { start, end } = getPeriodRange();

  if (isLoading) {
    return <div className="loading">Chargement en cours...</div>;
  }

  return (
    <div className="payments-page">
      <h1 className="page-title">Gestion des paiements</h1>
      
      {/* بطاقات الإحصائيات */}
      <Grid container spacing={3} className="stats-container">
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon total-icon">
                <PaidIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Total des paiements</Typography>
                <Typography variant="h4" component="p">{stats.total}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon confirmed-icon">
                <AccountBalanceIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Paiements confirmés</Typography>
                <Typography variant="h4" component="p">{stats.confirmes}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon pending-icon">
                <CreditCardIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">En attente</Typography>
                <Typography variant="h4" component="p">{stats.attente}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon amount-icon">
                <Typography variant="h6" component="div" className="currency">MRU</Typography>
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Montant total</Typography>
                <Typography variant="h4" component="p">{stats.montant.toLocaleString()}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      
      {/* التابات */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'white', borderRadius: '10px 10px 0 0' }}>
        <Tabs value={tabValue} onChange={handleTabChange} variant="fullWidth">
          <Tab icon={<ReceiptIcon />} label="Paiements" />
          <Tab icon={<InsightsIcon />} label="Analyses" />
        </Tabs>
      </Box>
      
      {/* أدوات البحث والفلترة */}
      {tabValue === 0 && (
        <div className="filters-container">
          <div className="search-box">
            <SearchIcon />
            <TextField
              variant="outlined"
              size="small"
              placeholder="Recherche par numéro de paiement, numéro de commande ou nom du client"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="filter-method">
            <FormControl variant="outlined" size="small">
              <InputLabel>Méthode de paiement</InputLabel>
              <Select
                value={methodFilter}
                onChange={(e) => setMethodFilter(e.target.value)}
                label="Méthode de paiement"
              >
                <MenuItem value="all">Toutes</MenuItem>
                <MenuItem value="Cash">Espèces</MenuItem>
                <MenuItem value="App">Application</MenuItem>
              </Select>
            </FormControl>
          </div>
          <div className="filter-status">
            <FormControl variant="outlined" size="small">
              <InputLabel>Statut</InputLabel>
              <Select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                label="Statut"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="Confirme">Confirmé</MenuItem>
                <MenuItem value="En Attente">En attente</MenuItem>
                <MenuItem value="Echoue">Échoué</MenuItem>
              </Select>
            </FormControl>
          </div>
        </div>
      )}
      {tabValue === 1 && (
        <Box p={2}>
          <Box display="flex" justifyContent="flex-end" alignItems="center" mb={2} mt={2} gap={2}>
            <FormControl variant="outlined" size="small" sx={{ minWidth: 180 }}>
              <InputLabel>La période</InputLabel>
              <Select
                value={period}
                onChange={e => setPeriod(e.target.value)}
                label="La période"
              >
                <MenuItem value="day">Le jour</MenuItem>
                <MenuItem value="week">La semaine</MenuItem>
                <MenuItem value="month">Le mois</MenuItem>
              </Select>
            </FormControl>
            <Button
              variant="outlined"
              color="secondary"
              startIcon={<InsightsIcon />}
              sx={{ borderRadius: 2, fontWeight: 700, boxShadow: 1, minWidth: 48 }}
              onClick={() => {
                const printContent = document.getElementById('payments-analytics-print');
                const adminUser = localStorage.getItem('adminUser') ? JSON.parse(localStorage.getItem('adminUser')) : null;
                const printWindow = window.open('', '', 'width=900,height=700');
                printWindow.document.write('<html><head><title>Analyse des paiements</title>');
                printWindow.document.write('<style>body{font-family:sans-serif;}h1{text-align:center;color:#2F9C95;}@media print{.MuiDialogActions-root{display:none;}} .stat-cards-print{display:flex;gap:16px;margin-bottom:24px;} .stat-card-print{flex:1;padding:16px 0;border-radius:10px;text-align:center;font-weight:700;font-size:18px;} .stat-confirm{background:#e8f5e9;color:#2e7d32;} .stat-attente{background:#fff8e1;color:#ff9800;} .stat-echoue{background:#ffebee;color:#c62828;} .logo-print{width:80px;margin-bottom:8px;display:block;margin-left:auto;margin-right:auto;} .print-header{margin-bottom:16px;} .print-meta{font-size:13px;color:#888;text-align:center;margin-bottom:8px;}</style>');
                printWindow.document.write('</head><body >');
                printWindow.document.write(`<div class='print-header'><img src='/Tawssil_logo.png' class='logo-print' alt='Logo' /><h1>Statistiques des paiements</h1></div>`);
                printWindow.document.write(`<div class='print-meta'>Imprimé le : ${new Date().toLocaleString('fr-FR')}<br>Imprimé par : ${(adminUser?.username || 'Admin')}</div>`);
                printWindow.document.write(printContent.innerHTML);
                printWindow.document.write('</body></html>');
                printWindow.document.close();
                printWindow.focus();
                printWindow.print();
              }}
            >
              Imprimer l'analyse
            </Button>
          </Box>
          <Box id="payments-analytics-print" sx={{ p: 3, background: 'linear-gradient(135deg, #f8fafc 60%, #e3f0ff 100%)', borderRadius: 4, boxShadow: 6 }}>
            {/* بطاقات إحصائية علوية */}
            <Box className="stat-cards-print" display="flex" gap={2} mb={3}>
              <Box className="stat-card-print stat-confirm">
                <div>Confirmé</div>
                <div style={{fontSize: '2rem', fontWeight: 900}}>{statusData.reduce((a, b) => a + (b.Confirme || 0), 0)}</div>
              </Box>
              <Box className="stat-card-print stat-attente">
                <div>En attente</div>
                <div style={{fontSize: '2rem', fontWeight: 900}}>{statusData.reduce((a, b) => a + (b['En Attente'] || 0), 0)}</div>
              </Box>
              <Box className="stat-card-print stat-echoue">
                <div>Échoué</div>
                <div style={{fontSize: '2rem', fontWeight: 900}}>{statusData.reduce((a, b) => a + (b.Echoue || 0), 0)}</div>
              </Box>
            </Box>
            <Box display="flex" alignItems="center" justifyContent="space-between" mb={1}>
              <Typography variant="subtitle1" color="textSecondary" sx={{ fontWeight: 700 }}>
                Analyse comparative des statuts de paiements pour la période sélectionnée.
              </Typography>
              <Box display="flex" flexDirection="column" alignItems="flex-end">
                <Typography variant="subtitle2" color="primary" sx={{ fontWeight: 700, fontSize: 16 }}>
                  Période : {period === 'day' ? 'Le jour' : period === 'week' ? 'La semaine' : 'Le mois'}
                </Typography>
                <Typography variant="body2" color="textSecondary" sx={{ fontWeight: 600 }}>
                  {start} - {end}
                </Typography>
              </Box>
            </Box>
            <Box sx={{ background: '#fff', borderRadius: 3, boxShadow: 2, p: 2, mb: 2 }}>
              <ResponsiveContainer width="100%" height={340}>
                <LineChart data={statusData} margin={{ top: 20, right: 30, left: 0, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="label" tick={{ fontWeight: 700, fontSize: 14 }} />
                  <YAxis allowDecimals={false} tick={{ fontWeight: 700 }} />
                  <Tooltip wrapperStyle={{ borderRadius: 8 }} contentStyle={{ fontWeight: 700 }} />
                  <Legend verticalAlign="top" height={36} iconType="circle" />
                  <Line type="monotone" dataKey="Confirme" stroke="#2e7d32" strokeWidth={3} dot={{ r: 6 }} activeDot={{ r: 8 }} name="Confirmé" />
                  <Line type="monotone" dataKey="En Attente" stroke="#ff9800" strokeWidth={3} dot={{ r: 6 }} activeDot={{ r: 8 }} name="En attente" />
                  <Line type="monotone" dataKey="Echoue" stroke="#c62828" strokeWidth={3} dot={{ r: 6 }} activeDot={{ r: 8 }} name="Échoué" />
                </LineChart>
              </ResponsiveContainer>
            </Box>
          </Box>
        </Box>
      )}
      
      {/* جدول المدفوعات */}
      {tabValue === 0 && (
        <TableContainer component={Paper} className="payments-table">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Numéro de paiement</TableCell>
                <TableCell>Numéro de commande</TableCell>
                <TableCell>Client</TableCell>
                <TableCell>Méthode de paiement</TableCell>
                <TableCell>Montant</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredPayments.map((payment) => (
                <TableRow key={payment.id}>
                  <TableCell>{payment.id}</TableCell>
                  <TableCell>{payment.orderId}</TableCell>
                  <TableCell>{payment.customerName}</TableCell>
                  <TableCell>
                    <div className="payment-method">
                      {getMethodIcon(payment.method)}
                      <span>{getMethodName(payment.method)}</span>
                    </div>
                  </TableCell>
                  <TableCell>{payment.amount.toLocaleString()} MRU</TableCell>
                  <TableCell>{payment.date}</TableCell>
                  <TableCell>{getStatusChip(payment.status)}</TableCell>
                  <TableCell>
                    <div className="action-buttons">
                      <IconButton size="small" title="Voir les détails" onClick={() => handleDetailsClick(payment)}>
                        <VisibilityIcon fontSize="small" />
                      </IconButton>
                      {payment.status === 'En Attente' && (
                        <>
                          <Button size="small" color="success" variant="contained" sx={{ ml: 1 }} onClick={() => handlePaymentStatus(payment.id, 'Confirme')}>Accepter</Button>
                          <Button size="small" color="error" variant="outlined" sx={{ ml: 1 }} onClick={() => handlePaymentStatus(payment.id, 'Echoue')}>Refuser</Button>
                        </>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
              {filteredPayments.length === 0 && (
                <TableRow>
                  <TableCell colSpan={10} align="center">
                    Aucun résultat correspondant aux critères de recherche
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}
      
      <Dialog open={openDetails} onClose={() => setOpenDetails(false)} maxWidth="xs" fullWidth PaperProps={{ sx: { borderRadius: 4, boxShadow: 8 } }}>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', bgcolor: '#f5f7fa', fontWeight: 700 }}>
          Détails du paiement
          <IconButton onClick={() => setOpenDetails(false)} size="small"><CloseIcon /></IconButton>
        </DialogTitle>
        <DialogContent dividers sx={{ p: 0, bgcolor: '#f8fafc' }}>
          {selectedPayment && (
            <Box sx={{ p: 3, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <Card sx={{ width: '100%', maxWidth: 370, boxShadow: 3, borderRadius: 3, p: 3, mb: 2, bgcolor: '#fff' }}>
                <Box display="flex" alignItems="center" mb={2}>
                  <PaidIcon sx={{ color: '#1976d2', fontSize: 48, mr: 2, bgcolor: '#e3f0ff', borderRadius: '50%', p: 1 }} />
                  <Typography variant="h5" fontWeight={800} color="#1976d2">{selectedPayment.id}</Typography>
                </Box>
                <Box mb={1}>
                  <Typography variant="subtitle2" color="text.secondary">Numéro de commande</Typography>
                  <Typography fontWeight={700} color="text.primary">{selectedPayment.orderId}</Typography>
                </Box>
                <Box mb={1}>
                  <Typography variant="subtitle2" color="text.secondary">Client</Typography>
                  <Typography fontWeight={700} color="text.primary">{selectedPayment.customerName}</Typography>
                </Box>
                <Box mb={1}>
                  <Typography variant="subtitle2" color="text.secondary">Montant</Typography>
                  <Typography fontWeight={700} color="#2e7d32">{selectedPayment.amount.toLocaleString()} MRU</Typography>
                </Box>
                <Box mb={1}>
                  <Typography variant="subtitle2" color="text.secondary">Date</Typography>
                  <Typography fontWeight={700} color="text.primary">{selectedPayment.date}</Typography>
                </Box>
                <Box mb={1}>
                  <Typography variant="subtitle2" color="text.secondary">Statut</Typography>
                  {getStatusChip(selectedPayment.status)}
                </Box>
                <Box mb={1}>
                  <Typography variant="subtitle2" color="text.secondary">Méthode de paiement</Typography>
                  <Box display="flex" alignItems="center">
                    {getMethodIcon(selectedPayment.method)}
                    <Typography fontWeight={700} ml={1}>{getMethodName(selectedPayment.method)}</Typography>
                  </Box>
                </Box>
                {selectedPayment.recu && (
                  <Box mb={1} textAlign="center">
                    <Typography variant="subtitle2" color="text.secondary" mb={0.5}>Reçu de paiement</Typography>
                    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                      <img src={selectedPayment.recu} alt="Reçu" style={{ maxWidth: 180, maxHeight: 180, borderRadius: 8, boxShadow: '0 2px 12px #0001', marginBottom: 8 }} />
                      <Button size="small" variant="outlined" color="primary" href={selectedPayment.recu} target="_blank">Voir l'image</Button>
                    </Box>
                  </Box>
                )}
              </Card>
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ bgcolor: '#f5f7fa' }}>
          <Button onClick={() => setOpenDetails(false)} color="primary" variant="contained">Fermer</Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default Payments; 