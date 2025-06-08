import React, { useState, useEffect } from 'react';
import { 
  Table, TableBody, TableCell, TableContainer, TableHead, 
  TableRow, Paper, TextField, /* Button, */ Select, MenuItem, 
  FormControl, InputLabel, Grid, Card, CardContent, Typography, IconButton, Button 
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
// import FilterListIcon from '@mui/icons-material/FilterList';
import PeopleIcon from '@mui/icons-material/People';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import StarIcon from '@mui/icons-material/Star';
import VisibilityIcon from '@mui/icons-material/Visibility';
import EditIcon from '@mui/icons-material/Edit';
import Dialog from '@mui/material/Dialog';
import CloseIcon from '@mui/icons-material/Close';
import EmailIcon from '@mui/icons-material/Email';
import PhoneIcon from '@mui/icons-material/Phone';
import HomeIcon from '@mui/icons-material/Home';
import CakeIcon from '@mui/icons-material/Cake';
import CalendarMonthIcon from '@mui/icons-material/CalendarMonth';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import LockOpenIcon from '@mui/icons-material/LockOpen';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import EditCalendarIcon from '@mui/icons-material/EditCalendar';
import Avatar from '@mui/material/Avatar';
import Chip from '@mui/material/Chip';
import Tooltip from '@mui/material/Tooltip';
import Box from '@mui/material/Box';
import './ClientManagement.css';
import axios from 'axios';

const ClientManagement = () => {
  const [clients, setClients] = useState([]);
  const [filteredClients, setFilteredClients] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [searchAdresse, setSearchAdresse] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [totalOrders, setTotalOrders] = useState(0);
  const [ordersAverage, setOrdersAverage] = useState(0);
  const [averageRating, setAverageRating] = useState(0);
  const [openDetails, setOpenDetails] = useState(false);
  const [selectedClient, setSelectedClient] = useState(null);
  const [updatingStatusId, setUpdatingStatusId] = useState(null);
  const [openStatusDialog, setOpenStatusDialog] = useState(false);
  const [statusClient, setStatusClient] = useState(null);

  useEffect(() => {
    // جلب بيانات العملاء الحقيقية من الباكند
    axios.get('http://localhost:8000/api/clients-table-stats/')
      .then(res => {
        setClients(res.data.clients || []);
        setFilteredClients(res.data.clients || []);
        setIsLoading(false);
      })
      .catch(() => setIsLoading(false));

    // جلب إحصائيات الطلبات
    axios.get('http://localhost:8000/api/commandes/commandes-stats/')
      .then(res => {
        setTotalOrders(res.data.total_commandes || 0);
        setOrdersAverage(res.data.moyenne || 0);
      });

    // جلب متوسط التقييم
    axios.get('http://localhost:8000/api/evaluations/clients-average-rating/')
      .then(res => {
        setAverageRating(res.data.note_moyenne || 0);
      });
  }, []);

  useEffect(() => {
    let result = [...clients];
    if (searchTerm) {
      result = result.filter(client => 
        client.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
        client.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        client.phone.includes(searchTerm)
      );
    }
    if (searchAdresse) {
      result = result.filter(client =>
        client.address && client.address.toLowerCase().includes(searchAdresse.toLowerCase())
      );
    }
    if (filterStatus !== 'all') {
      result = result.filter(client => client.status === filterStatus);
    }
    setFilteredClients(result);
  }, [searchTerm, searchAdresse, filterStatus, clients]);

  const handleViewDetails = (client) => {
    setSelectedClient(client);
    setOpenDetails(true);
  };

  const handleCloseDetails = () => {
    setOpenDetails(false);
    setSelectedClient(null);
  };

  const handleOpenStatusMenu = (client) => {
    setStatusClient(client);
    setOpenStatusDialog(true);
  };

  const handleCloseStatusDialog = () => {
    setOpenStatusDialog(false);
    setStatusClient(null);
  };

  const handleUpdateStatus = async (client, newStatus) => {
    setUpdatingStatusId(client.id);
    try {
      await axios.patch(
        `http://localhost:8000/api/users/${client.id}/update/`,
        { is_active: newStatus }
      );
      setClients(prev => prev.map(c => c.id === client.id ? { ...c, status: newStatus ? 'active' : 'inactive', is_active: newStatus } : c));
      setFilteredClients(prev => prev.map(c => c.id === client.id ? { ...c, status: newStatus ? 'active' : 'inactive', is_active: newStatus } : c));
    } catch (e) {}
    setUpdatingStatusId(null);
    handleCloseStatusDialog();
  };

  // مكون صف معلومات صغير
  const InfoRow = ({ icon, label, value }) => (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
      <span>{icon}</span>
      <Typography variant="subtitle2" fontWeight={700} sx={{ minWidth: 120 }}>{label}:</Typography>
      <Typography variant="body2" fontWeight={500} color="text.secondary">{value}</Typography>
    </Box>
  );

  if (isLoading) {
    return <div className="loading">Chargement...</div>;
  }

  return (
    <div className="client-management-page">
      <h1 className="page-title">Gestion des clients</h1>
      
      {/* بطاقات الإحصائيات */}
      <Grid container spacing={3} className="stats-container">
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon client-icon">
                <PeopleIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Total des clients</Typography>
                <Typography variant="h4" component="p">{clients.length}</Typography>
                <Typography variant="body2" color="textSecondary">
                  Clients actifs : {clients.filter(c => c.status === 'active').length}
                </Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon order-icon">
                <ShoppingCartIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Total des commandes</Typography>
                <Typography variant="h4" component="p">{totalOrders}</Typography>
                <Typography variant="body2" color="textSecondary">
                  Moyenne : {ordersAverage} par client
                </Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon rating-icon">
                <StarIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Note moyenne</Typography>
                <Typography variant="h4" component="p">{averageRating}</Typography>
                <Typography variant="body2" color="textSecondary">
                  sur 5.0
                </Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      
      {/* أدوات البحث والفلترة */}
      <div className="filters-container">
        <div className="search-box">
          <SearchIcon />
          <TextField
            variant="outlined"
            size="small"
            placeholder="Recherche par nom, e-mail ou téléphone"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="search-box">
          <SearchIcon />
          <TextField
            variant="outlined"
            size="small"
            placeholder="Recherche par adresse"
            value={searchAdresse}
            onChange={(e) => setSearchAdresse(e.target.value)}
          />
        </div>
        <div className="filter-status">
          <FormControl variant="outlined" size="small">
            <InputLabel>Statut</InputLabel>
            <Select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              label="Statut"
            >
              <MenuItem value="all">Tous</MenuItem>
              <MenuItem value="active">Actif</MenuItem>
              <MenuItem value="inactive">Inactif</MenuItem>
            </Select>
          </FormControl>
        </div>
      </div>
      
      {/* جدول العملاء */}
      <TableContainer component={Paper} className="clients-table">
        <Table aria-label="Tableau des clients">
          <TableHead>
            <TableRow>
              <TableCell>ID Client</TableCell>
              <TableCell>Nom</TableCell>
              <TableCell>E-mail</TableCell>
              <TableCell>Téléphone</TableCell>
              <TableCell>Adresse</TableCell>
              <TableCell>Commandes</TableCell>
              <TableCell>Total dépensé</TableCell>
              <TableCell>Note</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Date d'inscription</TableCell>
              <TableCell>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredClients.map((client) => (
              <TableRow key={client.id}>
                <TableCell>{client.id}</TableCell>
                <TableCell>{client.name}</TableCell>
                <TableCell>{client.email}</TableCell>
                <TableCell>{client.phone}</TableCell>
                <TableCell>{client.address}</TableCell>
                <TableCell>{client.ordersCount}</TableCell>
                <TableCell>{client.totalSpent} MRU</TableCell>
                <TableCell>{client.rating}</TableCell>
                <TableCell>
                  <span className={`status-badge status-${client.status}`}>
                    {client.status === 'active' ? 'Actif' : 'Inactif'}
                  </span>
                </TableCell>
                <TableCell>{client.registrationDate}</TableCell>
                <TableCell>
                  <IconButton color="primary" onClick={() => handleViewDetails(client)}>
                    <VisibilityIcon />
                  </IconButton>
                  <IconButton color="secondary" onClick={() => handleOpenStatusMenu(client)}>
                    <EditIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
            {filteredClients.length === 0 && (
              <TableRow>
                <TableCell colSpan={11} align="center">
                  Aucun résultat correspondant aux critères de recherche
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Dialog تفاصيل العميل */}
      <Dialog open={openDetails} onClose={handleCloseDetails} maxWidth="sm" fullWidth>
        {selectedClient && (
          <Box sx={{ bgcolor: "#fff", borderRadius: 4, boxShadow: 8, p: 0, overflow: "hidden" }}>
            {/* Header */}
            <Box sx={{
              position: "relative",
              bgcolor: "#2F9C95", // لون الـ dashboard الرئيسي
              py: 4,
              textAlign: "center"
            }}>
              <IconButton onClick={handleCloseDetails} sx={{ position: "absolute", top: 16, right: 16, bgcolor: "#fff" }}>
                <CloseIcon />
              </IconButton>
              <Avatar
                src={selectedClient.photo_profile || "/default-avatar.png"}
                sx={{
                  width: 100, height: 100, mx: "auto", mb: 1,
                  border: "4px solid #fff", boxShadow: 2
                }}
              />
              <Typography variant="h4" fontWeight={900} color="#fff" sx={{ letterSpacing: 1 }}>
                {selectedClient.name}
              </Typography>
              <Chip label="Client" sx={{
                mt: 1, bgcolor: "#fff", color: "#2F9C95", fontWeight: 700, fontSize: 14
              }} />
            </Box>
            {/* Main Info */}
            <Box sx={{ p: 3, bgcolor: "#f8fafb" }}>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<EmailIcon sx={{ color: "#2F9C95" }} />} label="Email" value={selectedClient.email} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<PhoneIcon sx={{ color: "#2F9C95" }} />} label="Téléphone" value={selectedClient.phone} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<HomeIcon sx={{ color: "#2F9C95" }} />} label="Adresse" value={selectedClient.address || "-"} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<CakeIcon sx={{ color: "#2F9C95" }} />} label="Date de naissance" value={selectedClient.date_naissance || "-"} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<CalendarMonthIcon sx={{ color: "#2F9C95" }} />} label="Date de création" value={selectedClient.registrationDate || "-"} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<ShoppingCartIcon sx={{ color: "#2F9C95" }} />} label="Commandes" value={selectedClient.ordersCount} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<MonetizationOnIcon sx={{ color: "#2F9C95" }} />} label="Total dépensé" value={selectedClient.totalSpent + " MRU"} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <InfoRow icon={<StarIcon sx={{ color: "#2F9C95" }} />} label="Note" value={selectedClient.rating} />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.5, position: "relative" }}>
                    <LockOpenIcon sx={{ color: selectedClient.is_active ? "#43a047" : "#e53935" }} />
                    <Typography variant="subtitle2" fontWeight={700} sx={{ minWidth: 80 }}>Statut:</Typography>
                    <Chip
                      label={selectedClient.is_active ? "Actif" : "Inactif"}
                      sx={{
                        bgcolor: selectedClient.is_active ? "#43a047" : "#e53935",
                        color: "#fff", fontWeight: 700, px: 2, fontSize: 15,
                        transition: "box-shadow 0.2s",
                        boxShadow: "none",
                        "&:hover .edit-icon": { opacity: 1 }
                      }}
                      icon={
                        <Tooltip title="Changer le statut du client">
                          <IconButton
                            size="small"
                            onClick={() => handleUpdateStatus(selectedClient, !selectedClient.is_active)}
                            disabled={updatingStatusId === selectedClient.id}
                            className="edit-icon"
                            sx={{ ml: 0.5, opacity: 0, transition: "opacity 0.2s" }}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      }
                    />
                  </Box>
                </Grid>
              </Grid>
            </Box>
            {/* Footer */}
            <Box sx={{ bgcolor: "#f1f3f4", px: 3, py: 2, mt: 2 }}>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <InfoRow icon={<AccessTimeIcon sx={{ color: "#b0b0b0" }} />} label="Dernière connexion" value={selectedClient.last_login || "-"} />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <InfoRow icon={<EditCalendarIcon sx={{ color: "#b0b0b0" }} />} label="Dernière modification" value={selectedClient.last_modified || "-"} />
                </Grid>
              </Grid>
            </Box>
          </Box>
        )}
      </Dialog>

      {/* Dialog تغيير حالة العميل */}
      <Dialog open={openStatusDialog} onClose={handleCloseStatusDialog} maxWidth="xs">
        <Box sx={{ p: 3, textAlign: 'center' }}>
          <Typography variant="h6" fontWeight={700} mb={2}>
            Modifier le statut du client
          </Typography>
          {statusClient && (
            <>
              <Typography mb={2}>
                Client: <b>{statusClient.name}</b>
              </Typography>
              <Button
                variant={statusClient.is_active ? 'outlined' : 'contained'}
                color="success"
                sx={{ mr: 2, minWidth: 120 }}
                disabled={statusClient.is_active}
                onClick={() => handleUpdateStatus(statusClient, true)}
              >
                Activer
              </Button>
              <Button
                variant={!statusClient.is_active ? 'outlined' : 'contained'}
                color="error"
                sx={{ minWidth: 120 }}
                disabled={!statusClient.is_active}
                onClick={() => handleUpdateStatus(statusClient, false)}
              >
                Désactiver
              </Button>
            </>
          )}
        </Box>
      </Dialog>
    </div>
  );
};

export default ClientManagement; 