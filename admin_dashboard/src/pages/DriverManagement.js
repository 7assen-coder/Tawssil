import React, { useState, useEffect } from 'react';
import { 
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, 
  Paper, Button, Dialog, DialogTitle, DialogContent, DialogActions, 
  TextField, IconButton, Typography, Grid, Box, Card, CardContent,
  Avatar, Chip, Rating, FormControl, InputLabel, Select, MenuItem, Menu,
  InputAdornment
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import VisibilityIcon from '@mui/icons-material/Visibility';
import DescriptionIcon from '@mui/icons-material/Description';
import DriveEtaIcon from '@mui/icons-material/DriveEta';
import PersonIcon from '@mui/icons-material/Person';
import EmailIcon from '@mui/icons-material/Email';
import PhoneIcon from '@mui/icons-material/Phone';
import DateRangeIcon from '@mui/icons-material/DateRange';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import BadgeIcon from '@mui/icons-material/Badge';
import FolderIcon from '@mui/icons-material/Folder';
import FileOpenIcon from '@mui/icons-material/FileOpen';
import StarIcon from '@mui/icons-material/Star';
import PublicIcon from '@mui/icons-material/Public';
import EditIcon from '@mui/icons-material/Edit';
import PrintIcon from '@mui/icons-material/Print';
import SearchIcon from '@mui/icons-material/Search';
import FilterListIcon from '@mui/icons-material/FilterList';
import ClearIcon from '@mui/icons-material/Clear';
import './DriverManagement.css';
import axios from 'axios';
import MuiAlert from '@mui/material/Alert';
import Snackbar from '@mui/material/Snackbar';
import * as XLSX from 'xlsx';
import htmlDocx from 'html-docx-js/dist/html-docx';

// ترجمة النصوص للفرنسية
const fr = {
  pageTitle: 'Gestion des chauffeurs',
  addDriver: 'Ajouter un chauffeur',
  fullName: 'Nom complet',
  email: 'E-mail',
  phone: 'Numéro de téléphone',
  address: 'Adresse',
  birthDate: 'Date de naissance',
  profilePhoto: 'Photo de profil',
  driverType: 'Type de chauffeur',
  vehicleType: 'Type de véhicule',
  vehiclePlate: 'Immatriculation',
  coverageZone: 'Zone de couverture',
  vehiclePhoto: 'Photo du véhicule',
  licensePhoto: 'Permis de conduire',
  carteGrisePhoto: 'Carte grise',
  insurancePhoto: 'Assurance',
  vignettePhoto: 'Vignette',
  municipalCardPhoto: 'Carte municipale',
  save: 'Enregistrer',
  cancel: 'Annuler',
  requiredFields: 'Veuillez remplir tous les champs obligatoires',
  newRequests: 'Nouvelles demandes de chauffeurs',
  allDrivers: 'Liste de tous les chauffeurs',
  type: 'Type',
  member: 'Membre',
  notMember: 'Non membre',
  status: 'Statut',
  actions: 'Actions',
  details: 'Détails',
  accept: 'Accepter',
  reject: 'Refuser',
  reasonReject: 'Motif du refus',
  reasonRejectPlaceholder: 'Exemple : Documents incomplets, véhicule non conforme, etc.',
  noNewRequests: 'Aucune nouvelle demande pour le moment',
  noDrivers: 'Aucun chauffeur accepté pour le moment',
  available: 'Disponible',
  unavailable: 'Indisponible',
  rating: 'Note moyenne',
  verificationStatus: 'Statut de vérification',
  verificationDate: 'Date de vérification',
  requestDate: 'Date de la demande',
  documents: 'Documents et photos',
  clickToView: "Cliquez sur le document pour l'agrandir",
  close: 'Fermer',
  approveDriver: 'Accepter le chauffeur',
  refuseDriver: 'Refuser le chauffeur',
  deleteDriver: 'Supprimer le chauffeur',
  renewMembership: "Renouveler l'adhésion",
  cancelMembership: "Annuler l'adhésion",
  active: 'Actif',
  notActive: 'Inactif',
  search: 'Rechercher',
};

// دالة مساعدة لتحويل أي تاريخ إلى yyyy-mm-dd
function toISODateString(dateStr) {
  if (!dateStr) return '';
  // إذا كان أصلاً بالتنسيق الصحيح
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return dateStr;
  // إذا كان بالتنسيق dd-mm-yyyy أو dd/mm/yyyy
  const match = dateStr.match(/^(\d{2})[-/](\d{2})[-/](\d{4})$/);
  if (match) {
    const [, dd, mm, yyyy] = match;
    return `${yyyy}-${mm.padStart(2, '0')}-${dd.padStart(2, '0')}`;
  }
  // إذا كان بالتنسيق mm/dd/yyyy
  const matchUS = dateStr.match(/^(\d{2})[-/](\d{2})[-/](\d{4})$/);
  if (matchUS) {
    const [, mm, dd, yyyy] = matchUS;
    return `${yyyy}-${mm.padStart(2, '0')}-${dd.padStart(2, '0')}`;
  }
  // إذا لم يتعرف عليه أعده كما هو
  return dateStr;
}

// دالة لحساب حالة السائق حسب الفترات الزمنية
function estDisponible(disponibilite) {
  if (typeof disponibilite === 'boolean') {
    return disponibilite;
  }
  if (!disponibilite || typeof disponibilite !== 'string') return false;
  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const intervals = disponibilite.split(',').map(interval => interval.trim());
  for (let interval of intervals) {
    const [start, end] = interval.split('-');
    if (!start || !end) continue;
    const [startH, startM] = start.split(':').map(Number);
    const [endH, endM] = end.split(':').map(Number);
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;
    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      return true;
    }
  }
  return false;
}

const DriverManagement = () => {
  const [drivers, setDrivers] = useState([]);
  const [allDrivers, setAllDrivers] = useState([]);
  const [filterType, setFilterType] = useState('all');
  const [isLoading, setIsLoading] = useState(true);
  const [openRejectDialog, setOpenRejectDialog] = useState(false);
  const [openDetailsDialog, setOpenDetailsDialog] = useState(false);
  const [selectedDriverId, setSelectedDriverId] = useState(null);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [openAddDriverDialog, setOpenAddDriverDialog] = useState(false);
  const [newDriver, setNewDriver] = useState({
    username: '',
    email: '',
    password: '',
    telephone: '',
    adresse: '',
    date_naissance: '',
    photo_profile: null,
    type: 'Livreur',
    type_vehicule: '',
    matricule_vehicule: '',
    photo_vehicule: null,
    photo_permis: null,
    photo_carte_grise: null,
    photo_assurance: null,
    photo_vignette: null,
    photo_carte_municipale: null,
    zone_couverture: '',
    disponibilite: '',
    latitude: '',
    longitude: '',
  });
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'error' });
  const [openEditMemberDialog, setOpenEditMemberDialog] = useState(false);
  const [editMemberDriver, setEditMemberDriver] = useState(null);
  const [editMembership, setEditMembership] = useState('');
  const [editRefuseReason, setEditRefuseReason] = useState('');
  const [openPrintDialog, setOpenPrintDialog] = useState(false);
  const [printDrivers, setPrintDrivers] = useState([]);
  const [exportAnchorEl, setExportAnchorEl] = useState(null);
  const [openExportDialog, setOpenExportDialog] = useState(false);
  const [exportType, setExportType] = useState('');
  // إضافة حالات جديدة للبحث والتصفية
  const [searchQuery, setSearchQuery] = useState('');
  const [searchField, setSearchField] = useState('all');
  const [openFilterMenu, setOpenFilterMenu] = useState(false);
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterVehicleType, setFilterVehicleType] = useState('all');
  const [filterMembership, setFilterMembership] = useState('all');
  // eslint-disable-next-line no-unused-vars
  const [adminUser, setAdminUser] = useState(() => {
    const stored = localStorage.getItem('adminUser');
    return stored ? JSON.parse(stored) : null;
  });

  useEffect(() => {
    fetchDrivers();
    // تحديث بيانات المسؤول من localStorage عند تحميل الصفحة
    const stored = localStorage.getItem('adminUser');
    if (stored) setAdminUser(JSON.parse(stored));
  }, []);

  useEffect(() => {
    if (openAddDriverDialog && 'geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setNewDriver(prev => ({
            ...prev,
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          }));
        },
        (error) => {
          // يمكن تجاهل الخطأ أو إظهار رسالة
        }
      );
    }
  }, [openAddDriverDialog]);

  const fetchDrivers = async () => {
    setIsLoading(true);
    try {
      const res = await axios.get('http://localhost:8000/api/list-drivers/');
      if (res.data.status === 'success') {
        setAllDrivers(res.data.drivers);
        setDrivers(res.data.drivers.filter(driver => driver.statut_verification === 'En attente'));
      }
    } catch (err) {
      setAllDrivers([]);
      setDrivers([]);
    }
    setIsLoading(false);
  };

  const handleViewDetails = (driverId) => {
    const driver = drivers.find(d => d.id === driverId);
    setSelectedDriver(driver);
    setOpenDetailsDialog(true);
  };

  const handleCloseDetailsDialog = () => {
    setOpenDetailsDialog(false);
    setSelectedDriver(null);
  };

  const handleApprove = async (driverId) => {
    const driver = drivers.find(d => d.id === driverId) || allDrivers.find(d => d.id === driverId);
    if (!driver) return;
    try {
      await axios.patch(`http://localhost:8000/api/drivers/${driverId}/update-verification/`, { statut_verification: 'Approuvé' });
      await fetchDrivers();
      setOpenDetailsDialog(false);
    } catch (err) {
      alert('Erreur lors de la validation du chauffeur');
    }
  };

  const handleOpenRejectDialog = (driverId) => {
    setSelectedDriverId(driverId);
    setOpenRejectDialog(true);
  };

  const handleCloseRejectDialog = () => {
    setOpenRejectDialog(false);
    setSelectedDriverId(null);
    setRejectReason('');
  };

  const handleReject = async () => {
    if (!rejectReason) return;
    try {
      await axios.patch(`http://localhost:8000/api/drivers/${selectedDriverId}/update-verification/`, {
        statut_verification: 'Refusé',
        raison_refus: rejectReason
      });
      await fetchDrivers();
    handleCloseRejectDialog();
    } catch (err) {
      alert('Erreur lors du refus du chauffeur');
    }
  };

  const getDriverType = (type) => {
    switch(type) {
      case 'Livreur':
        return 'Livreur';
      case 'Chauffeur':
        return 'Chauffeur';
      default:
        return type;
    }
  };

  // دالة جديدة للبحث والتصفية
  const filterDrivers = (driver) => {
    if (!driver) return false;
    
    // تصفية حسب نوع السائق
    if (filterType !== 'all' && driver.type !== filterType) return false;
    
    // تصفية حسب حالة التحقق
    if (driver.statut_verification !== 'Approuvé') return false;
    
    // تصفية حسب حالة التوفر
    if (filterStatus !== 'all') {
      const isAvailable = driver.disponibilite === true || driver.disponibilite === 1;
      if (filterStatus === 'available' && !isAvailable) return false;
      if (filterStatus === 'unavailable' && isAvailable) return false;
    }
    
    // تصفية حسب نوع المركبة
    if (filterVehicleType !== 'all' && driver.type_vehicule !== filterVehicleType) return false;
    
    // تصفية حسب نوع العضوية
    if (filterMembership !== 'all') {
      if (filterMembership === 'member' && driver.statut_verification !== 'Approuvé') return false;
      if (filterMembership === 'nonmember' && driver.statut_verification === 'Approuvé') return false;
    }
    
    // البحث النصي
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      
      if (searchField === 'all') {
        return (
          (driver.username && driver.username.toLowerCase().includes(query)) ||
          (driver.email && driver.email.toLowerCase().includes(query)) ||
          (driver.telephone && driver.telephone.toLowerCase().includes(query)) ||
          (driver.matricule_vehicule && driver.matricule_vehicule.toLowerCase().includes(query)) ||
          (driver.zone_couverture && driver.zone_couverture.toLowerCase().includes(query))
        );
      } else if (searchField === 'username') {
        return driver.username && driver.username.toLowerCase().includes(query);
      } else if (searchField === 'email') {
        return driver.email && driver.email.toLowerCase().includes(query);
      } else if (searchField === 'telephone') {
        return driver.telephone && driver.telephone.toLowerCase().includes(query);
      } else if (searchField === 'matricule') {
        return driver.matricule_vehicule && driver.matricule_vehicule.toLowerCase().includes(query);
      } else if (searchField === 'zone') {
        return driver.zone_couverture && driver.zone_couverture.toLowerCase().includes(query);
      }
    }
    
    return true;
  };

  // تطبيق عوامل التصفية على قائمة السائقين
  const filteredAllDrivers = allDrivers.filter(filterDrivers);

  // دالة لإعادة تعيين عوامل التصفية
  const resetFilters = () => {
    setSearchQuery('');
    setSearchField('all');
    setFilterType('all');
    setFilterStatus('all');
    setFilterVehicleType('all');
    setFilterMembership('all');
  };

  // إعادة إضافة الدوال المفقودة
  const handleAddDriverChange = (field, value) => {
    setNewDriver(prev => ({ ...prev, [field]: value }));
  };

  const handleFileChange = (field, event) => {
    const file = event.target.files[0];
    if (file) {
      setNewDriver(prev => ({ ...prev, [field]: file }));
    }
  };

  const handleAddDriver = async () => {
    // تحقق من ملء جميع الحقول المطلوبة
    if (!newDriver.username || !newDriver.email || !newDriver.password || !newDriver.telephone || !newDriver.adresse || !newDriver.date_naissance || !newDriver.type || !newDriver.type_vehicule || !newDriver.matricule_vehicule || !newDriver.zone_couverture || !newDriver.disponibilite || !newDriver.photo_profile || !newDriver.photo_vehicule || !newDriver.photo_permis || !newDriver.photo_carte_grise || !newDriver.photo_assurance || !newDriver.photo_vignette || !newDriver.photo_carte_municipale) {
      setSnackbar({ open: true, message: 'Veuillez remplir tous les champs obligatoires', severity: 'warning' });
      return;
    }

    try {
      // تحويل type إلى type_utilisateur
      const driverData = { ...newDriver, type_utilisateur: newDriver.type };
      delete driverData.type;

      const formData = new FormData();
      Object.entries(driverData).forEach(([key, value]) => {
        if (key === 'date_naissance') {
          formData.append('date_naissance', toISODateString(value));
        } else if (value !== undefined && value !== null && value !== '') {
          formData.append(key, value);
        }
      });

      await axios.post('http://localhost:8000/api/create-driver/', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      setOpenAddDriverDialog(false);
      setNewDriver({
        username: '',
        email: '',
        password: '',
        telephone: '',
        adresse: '',
        date_naissance: '',
        photo_profile: null,
        type: 'Livreur',
        type_vehicule: '',
        matricule_vehicule: '',
        photo_vehicule: null,
        photo_permis: null,
        photo_carte_grise: null,
        photo_assurance: null,
        photo_vignette: null,
        photo_carte_municipale: null,
        zone_couverture: '',
        disponibilite: '',
        latitude: '',
        longitude: '',
      });
      fetchDrivers();
      setSnackbar({ open: true, message: 'Chauffeur ajouté avec succès', severity: 'success' });
    } catch (err) {
      let msg = "Erreur lors de l'ajout du chauffeur";
      if (err.response && err.response.data) {
        if (err.response.data.errors) {
          msg += "\n" + JSON.stringify(err.response.data.errors, null, 2);
        } else if (err.response.data.message) {
          msg += "\n" + err.response.data.message;
        }
      }
      console.error('Driver creation error:', err.response ? err.response.data : err);
      setSnackbar({ open: true, message: msg, severity: 'error' });
    }
  };

  if (isLoading) {
    return <div className="loading">Chargement...</div>;
  }

  const disponible = selectedDriver ? estDisponible(selectedDriver.disponibilite) : false;

  // دالة تصدير Excel
  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(printDrivers.map(driver => ({
      Nom: driver.username,
      Type: getDriverType(driver.type),
      Téléphone: driver.telephone,
      Email: driver.email,
      'Type véhicule': driver.type_vehicule,
      Immatriculation: driver.matricule_vehicule,
      'Zone couverture': driver.zone_couverture,
      'Date naissance': driver.date_naissance,
      'Date inscription': driver.date_demande,
      Note: driver.note_moyenne,
      Statut: driver.disponibilite ? 'Disponible' : 'Indisponible',
      Membre: driver.statut_verification === 'Approuvé' ? 'Membre' : driver.statut_verification === 'Refusé' ? 'Interdit' : 'Non membre',
    })));
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Chauffeurs');
    XLSX.writeFile(wb, 'liste_chauffeurs.xlsx');
  };

  // دالة تصدير Word
  const exportToWord = () => {
    const table = document.getElementById('print-preview-table');
    if (!table) return;
    const html = `<html><head><meta charset='utf-8'></head><body>${table.innerHTML}</body></html>`;
    const converted = htmlDocx.asBlob(html);
    const link = document.createElement('a');
    link.href = URL.createObjectURL(converted);
    link.download = 'liste_chauffeurs.docx';
    link.click();
  };

  return (
    <div className="driver-management-page">
      <h1 className="page-title">{fr.pageTitle}</h1>
      
      {/* القسم الأول: السائقون في انتظار القبول أو الرفض */}
      <div className="card" style={{ marginBottom: 32 }}>
        <Typography variant="h6" style={{ marginBottom: 16, color: '#3f51b5' }}>{fr.newRequests}</Typography>
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Nom complet</TableCell>
                <TableCell>Type de chauffeur</TableCell>
                <TableCell>Numéro de téléphone</TableCell>
                <TableCell>E-mail</TableCell>
                <TableCell>Type de véhicule</TableCell>
                <TableCell>Date de la demande</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {!drivers || drivers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center">{fr.noNewRequests}</TableCell>
                </TableRow>
              ) : (
                drivers.map((driver) => (
                  <TableRow key={driver.id}>
                    <TableCell>{driver.username || 'Non disponible'}</TableCell>
                    <TableCell>{driver.type}</TableCell>
                    <TableCell>{driver.telephone || 'Non disponible'}</TableCell>
                    <TableCell>{driver.email || 'Non disponible'}</TableCell>
                    <TableCell>{driver.type_vehicule || 'Non disponible'}</TableCell>
                    <TableCell>{driver.date_demande || 'Non disponible'}</TableCell>
                    <TableCell>
                      <span className={`status-badge status-${driver.statut_verification?.toLowerCase().replace(' ', '-')}`} style={{ minWidth: 90, display: 'inline-block', textAlign: 'center' }}>
                        {driver.statut_verification}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="action-buttons">
                        <IconButton 
                          size="small"
                          color="primary"
                          onClick={() => handleViewDetails(driver.id)}
                          title={fr.details}
                        >
                          <VisibilityIcon />
                        </IconButton>
                        <Button
                          variant="contained"
                          color="success"
                          size="small"
                          startIcon={<CheckCircleIcon />}
                          onClick={() => handleApprove(driver.id)}
                        >
                          {fr.accept}
                        </Button>
                        <Button
                          variant="contained"
                          color="error"
                          size="small"
                          startIcon={<CancelIcon />}
                          onClick={() => handleOpenRejectDialog(driver.id)}
                        >
                          {fr.reject}
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </div>

      {/* القسم الثاني: جميع السائقين المقبولين مع الفلترة */}
      <div className="card">
        <Typography variant="h6" style={{ marginBottom: 16, color: '#3f51b5' }}>{fr.allDrivers}</Typography>
        
        {/* إضافة شريط البحث والتصفية */}
        <Box 
          sx={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: 2,
            mb: 2,
            p: 2,
            backgroundColor: '#f5f5f5',
            borderRadius: 2,
            alignItems: 'center'
          }}
        >
          {/* شريط البحث */}
          <Box sx={{ display: 'flex', gap: 1, flexGrow: 1, flexBasis: { xs: '100%', md: 'auto' } }}>
            <TextField
              variant="outlined"
              size="small"
              placeholder={fr.search}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ flexGrow: 1, minWidth: 200 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
                endAdornment: searchQuery && (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={() => setSearchQuery('')}>
                      <ClearIcon fontSize="small" />
                    </IconButton>
                  </InputAdornment>
                )
              }}
            />
            
            <FormControl variant="outlined" size="small" sx={{ minWidth: 150 }}>
              <InputLabel>Rechercher par</InputLabel>
              <Select
                value={searchField}
                onChange={(e) => setSearchField(e.target.value)}
                label="Rechercher par"
              >
                <MenuItem value="all">Tous les champs</MenuItem>
                <MenuItem value="username">Nom complet</MenuItem>
                <MenuItem value="email">E-mail</MenuItem>
                <MenuItem value="telephone">Téléphone</MenuItem>
                <MenuItem value="matricule">Immatriculation</MenuItem>
                <MenuItem value="zone">Zone de couverture</MenuItem>
              </Select>
            </FormControl>
          </Box>
          
          {/* زر فلاتر متقدمة */}
          <Button 
            variant="outlined"
            startIcon={<FilterListIcon />}
            onClick={(e) => {
              setFilterAnchorEl(e.currentTarget);
              setOpenFilterMenu(true);
            }}
            sx={{ whiteSpace: 'nowrap' }}
          >
            Filtres avancés
          </Button>
          
          {/* زر إعادة تعيين الفلاتر */}
          <Button
            variant="text"
            color="secondary"
            onClick={resetFilters}
            size="small"
            sx={{ whiteSpace: 'nowrap' }}
          >
            Réinitialiser
          </Button>
          
          {/* عرض عدد النتائج */}
          <Typography variant="body2" color="textSecondary" sx={{ ml: 'auto', whiteSpace: 'nowrap' }}>
            {filteredAllDrivers.length} résultat{filteredAllDrivers.length !== 1 ? 's' : ''}
          </Typography>
        </Box>
        
        {/* قائمة الفلاتر المتقدمة */}
        <Menu
          anchorEl={filterAnchorEl}
          open={openFilterMenu}
          onClose={() => setOpenFilterMenu(false)}
          PaperProps={{
            style: {
              maxHeight: 400,
              width: '250px',
              padding: '8px',
            }
          }}
        >
          <Typography variant="subtitle2" sx={{ px: 2, py: 1, fontWeight: 'bold' }}>
            Filtres avancés
          </Typography>
          
          <Box sx={{ p: 1 }}>
            <FormControl fullWidth size="small" sx={{ mb: 2 }}>
              <InputLabel>Type de chauffeur</InputLabel>
              <Select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                label="Type de chauffeur"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="Livreur">Livreur</MenuItem>
                <MenuItem value="Chauffeur">Chauffeur</MenuItem>
              </Select>
            </FormControl>
            
            <FormControl fullWidth size="small" sx={{ mb: 2 }}>
              <InputLabel>Statut</InputLabel>
              <Select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                label="Statut"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="available">Disponible</MenuItem>
                <MenuItem value="unavailable">Indisponible</MenuItem>
              </Select>
            </FormControl>
            
            <FormControl fullWidth size="small" sx={{ mb: 2 }}>
              <InputLabel>Type de véhicule</InputLabel>
              <Select
                value={filterVehicleType}
                onChange={(e) => setFilterVehicleType(e.target.value)}
                label="Type de véhicule"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="Moto">Moto</MenuItem>
                <MenuItem value="Voiture">Voiture</MenuItem>
                <MenuItem value="Camion">Camion</MenuItem>
                <MenuItem value="Camionnette">Camionnette</MenuItem>
              </Select>
            </FormControl>
            
            <FormControl fullWidth size="small" sx={{ mb: 1 }}>
              <InputLabel>Adhésion</InputLabel>
              <Select
                value={filterMembership}
                onChange={(e) => setFilterMembership(e.target.value)}
                label="Adhésion"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="member">Membre</MenuItem>
                <MenuItem value="nonmember">Non membre</MenuItem>
              </Select>
            </FormControl>
            
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 2 }}>
              <Button
                variant="text"
                size="small"
                onClick={resetFilters}
              >
                Réinitialiser
              </Button>
              <Button
                variant="contained"
                size="small"
                onClick={() => setOpenFilterMenu(false)}
              >
                Appliquer
              </Button>
            </Box>
          </Box>
        </Menu>
        
        {/* عرض الفلاتر النشطة */}
        {(searchQuery || filterType !== 'all' || filterStatus !== 'all' || filterVehicleType !== 'all' || filterMembership !== 'all') && (
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 2 }}>
            {searchQuery && (
              <Chip 
                label={`Recherche: ${searchQuery}`} 
                size="small" 
                onDelete={() => setSearchQuery('')} 
                color="primary"
              />
            )}
            {filterType !== 'all' && (
              <Chip 
                label={`Type: ${filterType}`} 
                size="small" 
                onDelete={() => setFilterType('all')} 
              />
            )}
            {filterStatus !== 'all' && (
              <Chip 
                label={`Statut: ${filterStatus === 'available' ? 'Disponible' : 'Indisponible'}`} 
                size="small" 
                onDelete={() => setFilterStatus('all')} 
              />
            )}
            {filterVehicleType !== 'all' && (
              <Chip 
                label={`Véhicule: ${filterVehicleType}`} 
                size="small" 
                onDelete={() => setFilterVehicleType('all')} 
              />
            )}
            {filterMembership !== 'all' && (
              <Chip 
                label={`Adhésion: ${filterMembership === 'member' ? 'Membre' : 'Non membre'}`} 
                size="small" 
                onDelete={() => setFilterMembership('all')} 
              />
            )}
          </Box>
        )}
        
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>{fr.fullName}</TableCell>
                <TableCell>{fr.driverType}</TableCell>
                <TableCell>{fr.phone}</TableCell>
                <TableCell>{fr.email}</TableCell>
                <TableCell>{fr.vehicleType}</TableCell>
                <TableCell>{fr.rating}</TableCell>
                <TableCell>{fr.status}</TableCell>
                <TableCell>{fr.member}</TableCell>
                <TableCell>{fr.details}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {!filteredAllDrivers || filteredAllDrivers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={10} align="center">{fr.noDrivers}</TableCell>
                </TableRow>
              ) : (
                filteredAllDrivers.map((driver) => {
                  // تحديد حالة السائق بناءً على disponibilite
                  const isAvailable = driver.disponibilite === true || driver.disponibilite === 1;
                  // تحديد حالة العضوية بناءً على statut_verification
                  let memberLabel = fr.notMember;
                  let memberColor = 'default';
                  if (driver.statut_verification === 'Approuvé') {
                    memberLabel = fr.member;
                    memberColor = 'success';
                  } else if (driver.statut_verification === 'Refusé') {
                    memberLabel = 'Interdit';
                    memberColor = 'error';
                  }
                  return (
                  <TableRow key={driver.id}>
                    <TableCell>{driver.username || 'Non disponible'}</TableCell>
                    <TableCell>{getDriverType(driver.type)}</TableCell>
                    <TableCell>{driver.telephone || 'Non disponible '}</TableCell>
                    <TableCell>{driver.email || 'Non disponible'}</TableCell>
                    <TableCell>{driver.type_vehicule || 'Non disponible'}</TableCell>
                    <TableCell>
                      <Rating value={driver.note_moyenne || 0} precision={0.5} readOnly size="small" />
                    </TableCell>
                    <TableCell>
                        <div className={isAvailable ? "info-icon available-icon" : "info-icon unavailable-icon"} style={{margin: 'auto'}}>
                          {isAvailable ? <CheckCircleIcon /> : <CancelIcon />}
                      </div>
                    </TableCell>
                    <TableCell>
                        <Chip label={memberLabel} color={memberColor} size="small" />
                    </TableCell>
                    <TableCell>
                      <IconButton size="small" color="primary" onClick={() => { setSelectedDriver(driver); setOpenDetailsDialog(true); }} title={fr.details}>
                        <VisibilityIcon />
                      </IconButton>
                        <IconButton size="small" color="secondary" onClick={() => { setEditMemberDriver(driver); setEditMembership(driver.is_active === false ? 'Banned' : (driver.statut_verification === 'Approuvé' ? 'Member' : (driver.statut_verification === 'Refusé' ? 'Banned' : 'Non membre'))); setOpenEditMemberDialog(true); }} title="Modifier l'adhésion">
                        <EditIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </div>

      {/* زر إضافة سائق جديد */}
      <Box display="flex" justifyContent="flex-end" alignItems="center" mb={2} gap={2}>
        <Button
          variant="outlined"
          color="secondary"
          startIcon={<PrintIcon />}
          sx={{
            borderRadius: 2,
            fontWeight: 700,
            boxShadow: 1,
            minWidth: 48,
            '@media (max-width:600px)': { minWidth: 36, fontSize: 12, px: 1 },
          }}
          onClick={() => {
            setPrintDrivers(filteredAllDrivers);
            setOpenPrintDialog(true);
          }}
        >
          Imprimer la liste
        </Button>
        <Button variant="contained" color="primary" onClick={() => setOpenAddDriverDialog(true)}>
          {fr.addDriver}
        </Button>
      </Box>

      <Dialog open={openRejectDialog} onClose={handleCloseRejectDialog} maxWidth="sm" fullWidth>
        <DialogTitle>{fr.reasonReject}</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="textSecondary" gutterBottom>
            {fr.reasonRejectPlaceholder}
          </Typography>
          <TextField
            autoFocus
            margin="dense"
            label={fr.reasonReject}
            type="text"
            fullWidth
            multiline
            rows={4}
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            placeholder={fr.reasonRejectPlaceholder}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseRejectDialog} color="primary">
            {fr.cancel}
          </Button>
          <Button onClick={handleReject} color="error" disabled={!rejectReason}>
            {fr.reject}
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog 
        open={openDetailsDialog} 
        onClose={handleCloseDetailsDialog} 
        maxWidth="md" 
        fullWidth
        scroll="paper"
      >
        {selectedDriver && (
          <>
            <DialogTitle>
              <Box display="flex" alignItems="center" gap={2} mb={2}>
                <Avatar
                  src={selectedDriver.photo_profile || ''}
                  alt={selectedDriver.username}
                  sx={{ width: 80, height: 80, bgcolor: '#f5f5f5', fontSize: 36 }}
                >
                  {!selectedDriver.photo_profile && <PersonIcon sx={{ fontSize: 40, color: '#bbb' }} />}
                </Avatar>
                <Box>
                  <Typography variant="h6" fontWeight={700}>{selectedDriver.username}</Typography>
                  <Typography variant="body2" color="textSecondary">{selectedDriver.email}</Typography>
                  <Typography variant="body2" color="textSecondary">{selectedDriver.telephone}</Typography>
                </Box>
              </Box>
            </DialogTitle>
            <DialogContent dividers>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <Typography variant="h6" className="section-title">{fr.fullName}</Typography>
                  <Card className="info-section">
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={6} md={4}>
                          <Box className="info-item">
                            <PersonIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.fullName}</Typography>
                              <Typography variant="body1">{selectedDriver.username}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6} md={4}>
                          <Box className="info-item">
                            <EmailIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.email}</Typography>
                              <Typography variant="body1">{selectedDriver.email}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6} md={4}>
                          <Box className="info-item">
                            <PhoneIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.phone}</Typography>
                              <Typography variant="body1">{selectedDriver.telephone}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6} md={4}>
                          <Box className="info-item">
                            <DateRangeIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.birthDate}</Typography>
                              <Typography variant="body1">{selectedDriver.date_naissance || selectedDriver.utilisateur?.date_naissance || 'Non disponible'}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        {selectedDriver.statut_verification === 'Approuvé' && (
                          <Grid item xs={12} sm={6} md={4}>
                            <Box className="info-item">
                              <StarIcon className="info-icon" />
                              <div>
                                <Typography variant="body2" color="textSecondary">{fr.rating}</Typography>
                                <Rating value={selectedDriver.note_moyenne} precision={0.5} readOnly size="small" />
                              </div>
                            </Box>
                          </Grid>
                        )}
                        
                        <Grid item xs={12} sm={6} md={4}>
                          <Box className="info-item">
                            <div className={disponible ? "info-icon available-icon" : "info-icon unavailable-icon"}>
                              {disponible ? <CheckCircleIcon style={{ color: '#388e3c' }} /> : <CancelIcon style={{ color: '#d32f2f' }} />}
                            </div>
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.status}</Typography>
                              <Typography variant="body1" style={{ color: disponible ? '#388e3c' : '#d32f2f', fontWeight: 700 }}>
                                {disponible ? 'Disponible' : 'Indisponible'}
                              </Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box className="info-item">
                            <LocationOnIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.address}</Typography>
                              <Typography variant="body1">{selectedDriver.adresse || 'Non disponible'}</Typography>
                            </div>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid item xs={12}>
                  <Typography variant="h6" className="section-title">{fr.vehicleType}</Typography>
                  <Card className="info-section">
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={6}>
                          <Box className="info-item">
                            <DriveEtaIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.driverType}</Typography>
                              <Typography variant="body1">{getDriverType(selectedDriver.type)}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6}>
                          <Box className="info-item">
                            <DriveEtaIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.vehicleType}</Typography>
                              <Typography variant="body1">{selectedDriver.type_vehicule || 'Non disponible'}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6}>
                          <Box className="info-item">
                            <BadgeIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.vehiclePlate}</Typography>
                              <Typography variant="body1">{selectedDriver.matricule_vehicule || 'Non disponible'}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6}>
                          <Box className="info-item">
                            <PublicIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.coverageZone}</Typography>
                              <Typography variant="body1">{selectedDriver.zone_couverture || 'Non disponible'}</Typography>
                            </div>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>
                
                <Grid item xs={12}>
                  <Typography variant="h6" className="section-title">{fr.documents}</Typography>
                  <Card className="info-section">
                    <CardContent>
                      <Typography variant="subtitle2" gutterBottom color="textSecondary">
                        {fr.clickToView}
                      </Typography>
                      <div className="documents-container">
                        <div className="document-thumbnail" onClick={() => selectedDriver.photo_permis && window.open(selectedDriver.photo_permis, '_blank') }>
                          <div className="thumbnail-placeholder">
                            <DescriptionIcon />
                          </div>
                          <div className="thumbnail-title">{fr.licensePhoto}</div>
                        </div>
                        
                        <div className="document-thumbnail" onClick={() => selectedDriver.photo_vehicule && window.open(selectedDriver.photo_vehicule, '_blank') }>
                          <div className="thumbnail-placeholder">
                            <DriveEtaIcon />
                          </div>
                          <div className="thumbnail-title">{fr.vehiclePhoto}</div>
                        </div>
                        
                        <div className="document-thumbnail" onClick={() => selectedDriver.photo_carte_grise && window.open(selectedDriver.photo_carte_grise, '_blank') }>
                          <div className="thumbnail-placeholder">
                            <FileOpenIcon />
                          </div>
                          <div className="thumbnail-title">{fr.carteGrisePhoto}</div>
                        </div>
                        
                        <div className="document-thumbnail" onClick={() => selectedDriver.photo_assurance && window.open(selectedDriver.photo_assurance, '_blank') }>
                          <div className="thumbnail-placeholder">
                            <FileOpenIcon />
                          </div>
                          <div className="thumbnail-title">{fr.insurancePhoto}</div>
                        </div>
                        
                        <div className="document-thumbnail" onClick={() => selectedDriver.photo_vignette && window.open(selectedDriver.photo_vignette, '_blank') }>
                          <div className="thumbnail-placeholder">
                            <FileOpenIcon />
                          </div>
                          <div className="thumbnail-title">{fr.vignettePhoto}</div>
                        </div>
                        
                        <div className="document-thumbnail" onClick={() => selectedDriver.photo_carte_municipale && window.open(selectedDriver.photo_carte_municipale, '_blank') }>
                          <div className="thumbnail-placeholder">
                            <FolderIcon />
                          </div>
                          <div className="thumbnail-title">{fr.municipalCardPhoto}</div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </Grid>
                
                <Grid item xs={12}>
                  <Typography variant="h6" className="section-title">{fr.requestDate}</Typography>
                  <Card className="info-section">
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12} sm={6}>
                          <Box className="info-item">
                            <DateRangeIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.requestDate}</Typography>
                              <Typography variant="body1">{selectedDriver.date_demande}</Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12} sm={6}>
                          <Box className="info-item">
                            <VerifiedUserIcon className="info-icon" />
                            <div>
                              <Typography variant="body2" color="textSecondary">{fr.verificationStatus}</Typography>
                              <Typography variant="body1">
                                <span className={`status-badge status-${selectedDriver.statut_verification.toLowerCase().replace(' ', '-')}`}>
                                  {selectedDriver.statut_verification}
                                </span>
                              </Typography>
                            </div>
                          </Box>
                        </Grid>
                        
                        {selectedDriver.certification_date && (
                          <Grid item xs={12} sm={6}>
                            <Box className="info-item">
                              <DateRangeIcon className="info-icon" />
                              <div>
                                <Typography variant="body2" color="textSecondary">{fr.verificationDate}</Typography>
                                <Typography variant="body1">{selectedDriver.certification_date}</Typography>
                              </div>
                            </Box>
                          </Grid>
                        )}
                        
                        {selectedDriver.statut_verification === 'Refusé' && selectedDriver.raison_refus && (
                          <Grid item xs={12}>
                            <Box className="info-item-reject">
                              <CancelIcon className="info-icon-reject" />
                              <div>
                                <Typography variant="body2" color="error">{fr.reasonReject}</Typography>
                                <Typography variant="body1">{selectedDriver.raison_refus}</Typography>
                              </div>
                            </Box>
                          </Grid>
                        )}
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                {selectedDriver.latitude && selectedDriver.longitude && (
                  <Box height={250} borderRadius={2} overflow="hidden" boxShadow={2} mt={2}>
                    <iframe
                      title="Localisation du chauffeur"
                      width="100%"
                      height="250"
                      frameBorder="0"
                      style={{ border: 0 }}
                      src={`https://www.openstreetmap.org/export/embed.html?bbox=${selectedDriver.longitude-0.01},${selectedDriver.latitude-0.01},${selectedDriver.longitude+0.01},${selectedDriver.latitude+0.01}&layer=mapnik&marker=${selectedDriver.latitude},${selectedDriver.longitude}`}
                      allowFullScreen
                    ></iframe>
                  </Box>
                )}
              </Grid>
            </DialogContent>
            <DialogActions>
              <Button onClick={handleCloseDetailsDialog} color="primary">
                {fr.close}
              </Button>
              
              {selectedDriver.statut_verification === 'En attente' && (
                <>
                  <Button 
                    onClick={() => {
                      handleApprove(selectedDriver.id);
                      handleCloseDetailsDialog();
                    }} 
                    color="success" 
                    variant="contained"
                  >
                    {fr.approveDriver}
                  </Button>
                  <Button 
                    onClick={() => {
                      handleOpenRejectDialog(selectedDriver.id);
                      handleCloseDetailsDialog();
                    }} 
                    color="error" 
                    variant="contained"
                  >
                    {fr.refuseDriver}
                  </Button>
                </>
              )}
            </DialogActions>
          </>
        )}
      </Dialog>

      <Dialog open={openAddDriverDialog} onClose={() => setOpenAddDriverDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>{fr.addDriver}</DialogTitle>
        <DialogContent dividers>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField label="Nom complet" fullWidth margin="dense" value={newDriver.username} onChange={e => handleAddDriverChange('username', e.target.value)} required />
              <TextField label="E-mail" fullWidth margin="dense" value={newDriver.email} onChange={e => handleAddDriverChange('email', e.target.value)} required />
              <TextField label="Mot de passe" type="password" fullWidth margin="dense" value={newDriver.password} onChange={e => handleAddDriverChange('password', e.target.value)} required />
              <TextField label="Numéro de téléphone" fullWidth margin="dense" value={newDriver.telephone} onChange={e => handleAddDriverChange('telephone', e.target.value)} required />
              <TextField label="Adresse" fullWidth margin="dense" value={newDriver.adresse} onChange={e => handleAddDriverChange('adresse', e.target.value)} required />
              <TextField label="Date de naissance" type="date" fullWidth margin="dense" InputLabelProps={{ shrink: true }} value={newDriver.date_naissance} onChange={e => handleAddDriverChange('date_naissance', e.target.value)} required />
              <input accept="image/*,.pdf" type="file" id="photo-profile" onChange={e => handleFileChange('photo_profile', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-profile">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_profile ? 'Photo de profil sélectionnée' : 'Photo de profil'}
                </Button>
              </label>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth margin="dense">
                <InputLabel>Type de chauffeur</InputLabel>
                <Select value={newDriver.type} label="Type de chauffeur" onChange={e => handleAddDriverChange('type', e.target.value)}>
                  <MenuItem value="Livreur">Livreur</MenuItem>
                  <MenuItem value="Chauffeur">Chauffeur</MenuItem>
                </Select>
              </FormControl>
              <FormControl fullWidth margin="dense">
                <InputLabel>Type de véhicule</InputLabel>
                <Select
                  value={newDriver.type_vehicule}
                  label="Type de véhicule"
                  onChange={e => handleAddDriverChange('type_vehicule', e.target.value)}
                  required
                >
                  <MenuItem value="Moto">Moto</MenuItem>
                  <MenuItem value="Camionnette">Camionnette</MenuItem>
                  <MenuItem value="Voiture">Voiture</MenuItem>
                  <MenuItem value="Camion">Camion</MenuItem>
                </Select>
              </FormControl>
              <TextField label="Matricule du véhicule" fullWidth margin="dense" value={newDriver.matricule_vehicule} onChange={e => handleAddDriverChange('matricule_vehicule', e.target.value)} required />
              <TextField label="Zone de couverture (séparée par des virgules)" fullWidth margin="dense" value={newDriver.zone_couverture} onChange={e => handleAddDriverChange('zone_couverture', e.target.value)} required />
              <TextField label="Disponibilité (ex: 08:00-12:00,14:00-18:00)" fullWidth margin="dense" value={newDriver.disponibilite} onChange={e => handleAddDriverChange('disponibilite', e.target.value)} required />
              <input accept="image/*,.pdf" type="file" id="photo-vehicule" onChange={e => handleFileChange('photo_vehicule', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-vehicule">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_vehicule ? 'Photo du véhicule sélectionnée' : 'Photo du véhicule'}
                </Button>
              </label>
              <input accept="image/*,.pdf" type="file" id="photo-permis" onChange={e => handleFileChange('photo_permis', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-permis">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_permis ? 'Permis sélectionné' : 'Permis de conduire'}
                </Button>
              </label>
              <input accept="image/*,.pdf" type="file" id="photo-carte-grise" onChange={e => handleFileChange('photo_carte_grise', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-carte-grise">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_carte_grise ? 'Carte grise sélectionnée' : 'Carte grise'}
                </Button>
              </label>
              <input accept="image/*,.pdf" type="file" id="photo-assurance" onChange={e => handleFileChange('photo_assurance', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-assurance">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_assurance ? 'Assurance sélectionnée' : 'Assurance'}
                </Button>
              </label>
              <input accept="image/*,.pdf" type="file" id="photo-vignette" onChange={e => handleFileChange('photo_vignette', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-vignette">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_vignette ? 'Vignette sélectionnée' : 'Vignette'}
                </Button>
              </label>
              <input accept="image/*,.pdf" type="file" id="photo-carte-municipale" onChange={e => handleFileChange('photo_carte_municipale', e)} style={{ display: 'none' }} />
              <label htmlFor="photo-carte-municipale">
                <Button variant="outlined" component="span" fullWidth margin="dense">
                  {newDriver.photo_carte_municipale ? 'Carte municipale sélectionnée' : 'Carte municipale'}
                </Button>
              </label>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAddDriverDialog(false)} color="primary">{fr.cancel}</Button>
          <Button onClick={handleAddDriver} color="success" variant="contained">{fr.save}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openEditMemberDialog} onClose={() => setOpenEditMemberDialog(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Modifier l'adhésion du chauffeur</DialogTitle>
        <DialogContent>
          <FormControl fullWidth margin="dense">
            <InputLabel>Statut d'adhésion</InputLabel>
            <Select
              value={editMembership}
              label="Statut d'adhésion"
              onChange={e => {
                setEditMembership(e.target.value);
                if (e.target.value !== 'Banned') setEditRefuseReason('');
              }}
            >
              <MenuItem value="Member">Membre</MenuItem>
              <MenuItem value="Non membre">Non membre</MenuItem>
              <MenuItem value="Banned">Interdit</MenuItem>
            </Select>
          </FormControl>
          {editMembership === 'Banned' && (
            <TextField
              label="Motif du refus"
              fullWidth
              margin="dense"
              value={editRefuseReason}
              onChange={e => setEditRefuseReason(e.target.value)}
              placeholder="Exemple : Documents incomplets, véhicule non conforme, etc."
              required
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenEditMemberDialog(false)} color="primary">Annuler</Button>
          <Button onClick={async () => {
            if (!editMemberDriver) return;
            // تحديث العضوية في الباكند
            try {
              let statut_verification = 'En attente';
              let data = {};
              if (editMembership === 'Member') statut_verification = 'Approuvé';
              else if (editMembership === 'Banned') statut_verification = 'Refusé';
              data.statut_verification = statut_verification;
              if (statut_verification === 'Refusé') {
                data.raison_refus = editRefuseReason;
              }
              await axios.patch(`http://localhost:8000/api/drivers/${editMemberDriver.id}/update-verification/`, data);
              setOpenEditMemberDialog(false);
              setEditRefuseReason('');
              fetchDrivers();
            } catch (err) {
              alert("Erreur lors de la modification de l'adhésion");
            }
          }} color="success" variant="contained" disabled={editMembership === 'Banned' && !editRefuseReason}>Enregistrer</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openPrintDialog} onClose={() => setOpenPrintDialog(false)} maxWidth="lg" fullWidth>
        <DialogTitle sx={{ p: 0 }}>
          <Box display="flex" flexDirection="column" alignItems="center" justifyContent="center" py={3}>
            <img src="/Tawssil_logo.png" alt="Tawssil Logo" style={{ width: 120, marginBottom: 8 }} />
            <Typography variant="h5" fontWeight={800} color="#2F9C95" gutterBottom>
              Liste professionnelle des chauffeurs
            </Typography>
            <Typography variant="subtitle2" color="textSecondary">
              {`Date d'impression : ${new Date().toLocaleString('fr-FR')}`}
            </Typography>
            <Typography variant="subtitle2" color="textSecondary">
              {`Nombre total de chauffeurs : ${printDrivers.length}`}
            </Typography>
            <Typography variant="subtitle2" color="textSecondary">
              {`Imprimé par : ${adminUser?.username || 'Admin'} (${adminUser?.role || 'Administrateur'})`}
            </Typography>
          </Box>
        </DialogTitle>
        <DialogContent dividers>
          <Box id="print-preview-table" sx={{ p: 2, background: '#f8fafc', borderRadius: 3 }}>
            <TableContainer component={Paper} sx={{ boxShadow: 2, borderRadius: 3 }}>
              <Table size="small">
                <TableHead>
                  <TableRow sx={{ background: '#e0f2f1' }}>
                    <TableCell sx={{ fontWeight: 700 }}>Nom complet</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Type de chauffeur</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Numéro de téléphone</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>E-mail</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Type de véhicule</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Immatriculation</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Zone de couverture</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Date de naissance</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Date d'inscription</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Note moyenne</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Statut</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Membre</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {printDrivers.map((driver) => (
                    <TableRow key={driver.id}>
                      <TableCell>{driver.username || 'Non disponible'}</TableCell>
                      <TableCell>{getDriverType(driver.type)}</TableCell>
                      <TableCell>{driver.telephone || 'Non disponible '}</TableCell>
                      <TableCell>{driver.email || 'Non disponible'}</TableCell>
                      <TableCell>{driver.type_vehicule || 'Non disponible'}</TableCell>
                      <TableCell>{driver.matricule_vehicule || '-'}</TableCell>
                      <TableCell>{driver.zone_couverture || '-'}</TableCell>
                      <TableCell>{driver.date_naissance || '-'}</TableCell>
                      <TableCell>{driver.date_demande || '-'}</TableCell>
                      <TableCell>
                        <Rating value={driver.note_moyenne || 0} precision={0.5} readOnly size="small" />
                      </TableCell>
                      <TableCell>
                        <div className={driver.disponibilite ? "info-icon available-icon" : "info-icon unavailable-icon"} style={{margin: 'auto'}}>
                          {driver.disponibilite ? <CheckCircleIcon /> : <CancelIcon />}
                        </div>
                      </TableCell>
                      <TableCell>
                        {driver.statut_verification === 'Approuvé' ? fr.member : driver.statut_verification === 'Refusé' ? 'Interdit' : fr.notMember}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            {/* معلومات إضافية لكل سائق */}
            <Box mt={4}>
              <Typography variant="h6" fontWeight={700} color="#2F9C95" gutterBottom>
                Détails supplémentaires
              </Typography>
              {printDrivers.map((driver, idx) => (
                <Paper key={driver.id} sx={{ p: 2, mb: 2, background: idx % 2 === 0 ? '#f1f8e9' : '#e3f2fd', borderRadius: 2 }}>
                  <Typography variant="subtitle1" fontWeight={700} color="#333">
                    {driver.username} ({getDriverType(driver.type)})
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Email : {driver.email} | Téléphone : {driver.telephone}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Véhicule : {driver.type_vehicule} | Immatriculation : {driver.matricule_vehicule || '-'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Zone de couverture : {driver.zone_couverture || '-'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Date de naissance : {driver.date_naissance || '-'} | Date d'inscription : {driver.date_demande || '-'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Statut de vérification : {driver.statut_verification}
                  </Typography>
                  {driver.statut_verification === 'Refusé' && driver.raison_refus && (
                    <Typography variant="body2" color="error">
                      Motif du refus : {driver.raison_refus}
                    </Typography>
                  )}
                  <Typography variant="body2" color="textSecondary">
                    Nombre de livraisons/courses effectuées : {driver.deliveries_count || 0}
                  </Typography>
                  {driver.providers_info && (
                    <Typography variant="body2" color="textSecondary">
                      Fournisseurs associés : {driver.providers_info}
                    </Typography>
                  )}
                </Paper>
              ))}
            </Box>
            {/* توقيع المسؤول في أسفل الصفحة */}
            <Box mt={4} sx={{ textAlign: 'center', borderTop: '1px solid #ccc', pt: 2 }}>
              <Typography variant="subtitle1" fontWeight={700} color="#2F9C95">
                {adminUser?.username || 'Admin'} ({adminUser?.role || 'Administrateur'})
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Signature
              </Typography>
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenPrintDialog(false)} color="primary">FERMER</Button>
          <Button
            onClick={() => {
              const printContent = document.getElementById('print-preview-table');
              const printWindow = window.open('', '', 'width=900,height=700');
              printWindow.document.write('<html><head><title>Liste des chauffeurs</title>');
              printWindow.document.write('<style>body{font-family:sans-serif;}table{width:100%;border-collapse:collapse;}th,td{border:1px solid #ccc;padding:6px;text-align:left;}th{background:#e0f2f1;}h1{text-align:center;color:#2F9C95;}img{display:block;margin:0 auto 10px auto;width:100px;}@media print{.MuiDialogActions-root{display:none;}}</style>');
              printWindow.document.write('</head><body >');
              printWindow.document.write(`<img src='/Tawssil_logo.png' alt='Tawssil Logo' /><h1>Liste professionnelle des chauffeurs</h1>`);
              printWindow.document.write(printContent.innerHTML);
              printWindow.document.write('<div style="text-align:center;margin-top:20px;font-size:12px;color:#666;">Imprimé par : ' + (adminUser?.username || 'Admin') + ' (' + (adminUser?.role || 'Administrateur') + ')</div>');
              printWindow.document.write('</body></html>');
              printWindow.document.close();
              printWindow.focus();
              printWindow.print();
            }}
            color="success"
            variant="contained"
            startIcon={<PrintIcon />}
          >
            IMPRIMER
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            onClick={e => setExportAnchorEl(e.currentTarget)}
            sx={{ ml: 1 }}
          >
            Exporter
          </Button>
          <Menu anchorEl={exportAnchorEl} open={Boolean(exportAnchorEl)} onClose={() => setExportAnchorEl(null)}>
            <MenuItem onClick={() => { setExportType('pdf'); setExportAnchorEl(null); setOpenExportDialog(true); }}>PDF</MenuItem>
            <MenuItem onClick={() => { setExportType('excel'); setExportAnchorEl(null); setOpenExportDialog(true); }}>Excel</MenuItem>
            <MenuItem onClick={() => { setExportType('word'); setExportAnchorEl(null); setOpenExportDialog(true); }}>Word</MenuItem>
          </Menu>
          {/* Dialog اختيار نوع التصدير */}
          <Dialog open={openExportDialog} onClose={() => setOpenExportDialog(false)} maxWidth="xs" fullWidth>
            <DialogTitle>Exporter la liste</DialogTitle>
            <DialogContent>
              <Typography>Vous avez choisi d'exporter la liste des chauffeurs au format <b>{exportType.toUpperCase()}</b>.</Typography>
              <Typography mt={2}>Voulez-vous continuer ?</Typography>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setOpenExportDialog(false)} color="secondary">Annuler</Button>
              <Button onClick={() => {
                setOpenExportDialog(false);
                if (exportType === 'excel') exportToExcel();
                else if (exportType === 'word') exportToWord();
                else if (exportType === 'pdf') {
                  const printContent = document.getElementById('print-preview-table');
                  const printWindow = window.open('', '', 'width=900,height=700');
                  printWindow.document.write('<html><head><title>Liste des chauffeurs</title>');
                  printWindow.document.write('<style>body{font-family:sans-serif;}table{width:100%;border-collapse:collapse;}th,td{border:1px solid #ccc;padding:6px;text-align:left;}th{background:#e0f2f1;}h1{text-align:center;color:#2F9C95;}img{display:block;margin:0 auto 10px auto;width:100px;}@media print{.MuiDialogActions-root{display:none;}}</style>');
                  printWindow.document.write('</head><body >');
                  printWindow.document.write(`<img src='/Tawssil_logo.png' alt='Tawssil Logo' /><h1>Liste professionnelle des chauffeurs</h1>`);
                  printWindow.document.write(printContent.innerHTML);
                  printWindow.document.write('<div style="text-align:center;margin-top:20px;font-size:12px;color:#666;">Imprimé par : ' + (adminUser?.username || 'Admin') + ' (' + (adminUser?.role || 'Administrateur') + ')</div>');
                  printWindow.document.write('</body></html>');
                  printWindow.document.close();
                  printWindow.focus();
                  printWindow.print();
                }
              }} color="primary" variant="contained">Exporter</Button>
            </DialogActions>
          </Dialog>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={7000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'top', horizontal: 'center' }}>
        <MuiAlert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} sx={{ width: '100%' }} variant="filled">
          {snackbar.message.split('\n').map((line, idx) => <div key={idx}>{line}</div>)}
        </MuiAlert>
      </Snackbar>
    </div>
  );
};

export default DriverManagement; 