import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TextField,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Card,
  CardContent,
  Grid,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Search as SearchIcon,
  Email as EmailIcon,
  Sms as SmsIcon,
  Block as BlockIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  AccessTime as AccessTimeIcon,
} from '@mui/icons-material';
import axios from 'axios';
import { format } from 'date-fns';
import { ar } from 'date-fns/locale';

const OtpCodes = () => {
  const [otpCodes, setOtpCodes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');

  const fetchOtpCodes = async () => {
    try {
      setLoading(true);
      const response = await axios.get('http://localhost:8000/api/otp-codes/');
      setOtpCodes(response.data.otps);
      setError(null);
    } catch (err) {
      setError("Une erreur s'est produite lors du chargement des données");
      console.error('Error fetching OTP codes:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOtpCodes();
  }, []);

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const filteredOtpCodes = otpCodes.filter((otp) => {
    const matchesSearch = 
      otp.identifier.toLowerCase().includes(searchTerm.toLowerCase()) ||
      otp.code.includes(searchTerm) ||
      (otp.user_info && otp.user_info.username.toLowerCase().includes(searchTerm.toLowerCase()));
    
    const matchesType = filterType === 'all' || otp.type === filterType;
    const matchesStatus = filterStatus === 'all' || 
      (filterStatus === 'used' && otp.is_used) ||
      (filterStatus === 'unused' && !otp.is_used) ||
      (filterStatus === 'expired' && otp.is_expired) ||
      (filterStatus === 'blocked' && otp.is_blocked);

    return matchesSearch && matchesType && matchesStatus;
  });

  const getStatusChip = (otp) => {
    if (otp.is_blocked) {
      return <Chip icon={<BlockIcon />} label="Bloqué" color="error" size="small" />;
    }
    if (otp.is_used) {
      return <Chip icon={<CheckCircleIcon />} label="Utilisé" color="success" size="small" />;
    }
    if (otp.is_expired) {
      return <Chip icon={<CancelIcon />} label="Expiré" color="warning" size="small" />;
    }
    return <Chip icon={<AccessTimeIcon />} label="Actif" color="primary" size="small" />;
  };

  const getTypeIcon = (type) => {
    return type === 'EMAIL' ? <EmailIcon /> : <SmsIcon />;
  };

  const formatDate = (dateString) => {
    try {
      return format(new Date(dateString), 'dd MMM yyyy HH:mm:ss', { locale: ar });
    } catch (error) {
      return dateString;
    }
  };

  const formatTimeRemaining = (seconds) => {
    if (seconds <= 0) return 'Expiré';
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom sx={{ mb: 4, fontWeight: 'bold', color: 'primary.main' }}>
        Codes de vérification OTP
      </Typography>

      {/* إحصائيات سريعة */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total des codes
              </Typography>
              <Typography variant="h5">
                {otpCodes.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Codes actifs
              </Typography>
              <Typography variant="h5">
                {otpCodes.filter(otp => !otp.is_expired && !otp.is_used).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Codes expirés
              </Typography>
              <Typography variant="h5">
                {otpCodes.filter(otp => otp.is_expired).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Codes bloqués
              </Typography>
              <Typography variant="h5">
                {otpCodes.filter(otp => otp.is_blocked).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* أدوات البحث والفلترة */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <TextField
          label="Recherche"
          variant="outlined"
          size="small"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
          }}
          sx={{ minWidth: 200 }}
        />
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Type de code</InputLabel>
          <Select
            value={filterType}
            label="Type de code"
            onChange={(e) => setFilterType(e.target.value)}
          >
            <MenuItem value="all">Tous</MenuItem>
            <MenuItem value="EMAIL">E-mail</MenuItem>
            <MenuItem value="SMS">SMS</MenuItem>
          </Select>
        </FormControl>
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Statut</InputLabel>
          <Select
            value={filterStatus}
            label="Statut"
            onChange={(e) => setFilterStatus(e.target.value)}
          >
            <MenuItem value="all">Tous</MenuItem>
            <MenuItem value="used">Utilisé</MenuItem>
            <MenuItem value="unused">Non utilisé</MenuItem>
            <MenuItem value="expired">Expiré</MenuItem>
            <MenuItem value="blocked">Bloqué</MenuItem>
          </Select>
        </FormControl>
        <Tooltip title="Rafraîchir les données">
          <IconButton onClick={fetchOtpCodes} color="primary">
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>ID</TableCell>
                <TableCell>Code</TableCell>
                <TableCell>Identifiant</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Utilisateur</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Date de création</TableCell>
                <TableCell>Date d'expiration</TableCell>
                <TableCell>Temps restant</TableCell>
                <TableCell>Essais de vérification</TableCell>
                <TableCell>Bloqué</TableCell>
                <TableCell>Données d'inscription</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredOtpCodes
                .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                .map((otp) => (
                  <TableRow key={otp.id}>
                    <TableCell>{otp.id}</TableCell>
                    <TableCell>{otp.code}</TableCell>
                    <TableCell>{otp.identifier}</TableCell>
                    <TableCell>
                      <Chip
                        icon={getTypeIcon(otp.type)}
                        label={otp.type === 'EMAIL' ? 'E-mail' : 'SMS'}
                        size="small"
                        color={otp.type === 'EMAIL' ? 'primary' : 'secondary'}
                      />
                    </TableCell>
                    <TableCell>
                      {otp.user_info ? (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {otp.user_info.photo_profile && (
                            <img
                              src={otp.user_info.photo_profile}
                              alt={otp.user_info.username}
                              style={{ width: 24, height: 24, borderRadius: '50%' }}
                            />
                          )}
                          <Typography variant="body2">
                            {otp.user_info.username} <br />
                            <span style={{ color: '#888', fontSize: 12 }}>{otp.user_info.email}</span>
                          </Typography>
                        </Box>
                      ) : (
                        <Typography variant="body2" color="textSecondary">
                          Aucun utilisateur associé
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>{getStatusChip(otp)}</TableCell>
                    <TableCell>{formatDate(otp.created_at)}</TableCell>
                    <TableCell>{formatDate(otp.expires_at)}</TableCell>
                    <TableCell>
                      <Chip
                        icon={<AccessTimeIcon />}
                        label={formatTimeRemaining(otp.time_remaining)}
                        size="small"
                        color={otp.time_remaining > 0 ? 'primary' : 'error'}
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={otp.verification_attempts}
                        size="small"
                        color={otp.verification_attempts > 0 ? 'warning' : 'default'}
                      />
                    </TableCell>
                    <TableCell>
                      {otp.is_blocked ? (
                        <Chip label="Oui" color="error" size="small" />
                      ) : (
                        <Chip label="Non" color="success" size="small" />
                      )}
                    </TableCell>
                    <TableCell>
                      {otp.registration_data ? (
                        <Box sx={{ fontSize: 13, color: '#333', lineHeight: 1.5 }}>
                          {otp.registration_data.full_name && (
                            <div><b>Nom:</b> {otp.registration_data.full_name}</div>
                          )}
                          {otp.registration_data.email && (
                            <div><b>E-mail:</b> {otp.registration_data.email}</div>
                          )}
                          {otp.registration_data.user_type && (
                            <div><b>Type:</b> {otp.registration_data.user_type}</div>
                          )}
                          {otp.registration_data.birth_date && (
                            <div><b>Date de naissance:</b> {otp.registration_data.birth_date}</div>
                          )}
                          {/* إذا كانت هناك بيانات أخرى */}
                          {Object.keys(otp.registration_data).filter(k => !['full_name','email','user_type','birth_date'].includes(k)).map(k => (
                            <div key={k}><b>{k}:</b> {String(otp.registration_data[k])}</div>
                          ))}
                        </Box>
                      ) : (
                        <Typography variant="caption" color="textSecondary">Aucune</Typography>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
            </TableBody>
          </Table>
          <TablePagination
            rowsPerPageOptions={[5, 10, 25, 50, 100]}
            component="div"
            count={filteredOtpCodes.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
            labelRowsPerPage="Lignes par page"
            labelDisplayedRows={({ from, to, count }) => `${from}-${to} sur ${count}`}
          />
        </TableContainer>
      )}
    </Box>
  );
};

export default OtpCodes; 