import React, { useState, useEffect, useCallback } from 'react';
import './AdminWorkers.css';
import { Box, Card, CardContent, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton, Button, Dialog, DialogTitle, DialogContent, TextField, MenuItem, Avatar, Stepper, Step, StepLabel, Snackbar, Alert, Grid, Chip, InputAdornment } from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import SupervisorAccountIcon from '@mui/icons-material/SupervisorAccount';
import PersonIcon from '@mui/icons-material/Person';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import VisibilityIcon from '@mui/icons-material/Visibility';
import EmailIcon from '@mui/icons-material/Email';
import BadgeIcon from '@mui/icons-material/Badge';
import PhoneIcon from '@mui/icons-material/Phone';
import HomeIcon from '@mui/icons-material/Home';
import CalendarMonthIcon from '@mui/icons-material/CalendarMonth';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import CloseIcon from '@mui/icons-material/Close';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import SearchIcon from '@mui/icons-material/Search';
import ClearIcon from '@mui/icons-material/Clear';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import PrintIcon from '@mui/icons-material/Print';

const roleIcons = {
  'Directeur général': <AdminPanelSettingsIcon color="primary" fontSize="small" />,
  'Superviseur': <SupervisorAccountIcon color="info" fontSize="small" />,
  'Employé': <PersonIcon color="action" fontSize="small" />,
};

const AdminWorkers = () => {
  const [admins, setAdmins] = useState([]);
  const [openAdd, setOpenAdd] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchField, setSearchField] = useState('nom');
  const [filteredAdmins, setFilteredAdmins] = useState([]);
  const [newAdmin, setNewAdmin] = useState({
    nom: '',
    email: '',
    password: '',
    telephone: '',
    adresse: '',
    date_naissance: '',
    photo_profile: null,
    is_active: true,
    is_staff: true,
    is_superuser: false,
    role: 'Employé'
  });
  const [selectedAdmin, setSelectedAdmin] = useState(null);
  const [openDetails, setOpenDetails] = useState(false);
  const [photoPreview, setPhotoPreview] = useState(null);
  const steps = ['Informations principales', 'Détails supplémentaires'];
  const [activeStep, setActiveStep] = useState(0);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [errors, setErrors] = useState({});
  const [checking, setChecking] = useState({ nom: false, email: false, telephone: false });
  const [globalError, setGlobalError] = useState('');
  const [openEdit, setOpenEdit] = useState(false);
  const [editAdmin, setEditAdmin] = useState(null);
  const [editLoading, setEditLoading] = useState(false);
  const [editError, setEditError] = useState('');
  const [photoEditPreview, setPhotoEditPreview] = useState(null);
  const [openDelete, setOpenDelete] = useState(false);
  const [adminToDelete, setAdminToDelete] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const fetchAdmins = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/administrateurs/', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      if (data.status === 'success') {
        setAdmins(data.administrateurs || []);
      } else {
        setAdmins([]);
      }
    } catch (error) {
      setAdmins([]);
    }
  };

  useEffect(() => {
    fetchAdmins();
  }, []);

  const handleAdd = async () => {
    if (!newAdmin.nom || !newAdmin.email || !newAdmin.password) {
      setSnackbar({ open: true, message: 'Veuillez remplir tous les champs obligatoires.', severity: 'error' });
      return;
    }
    try {
      const formData = new FormData();
      formData.append('nom', newAdmin.nom);
      formData.append('email', newAdmin.email);
      formData.append('password', newAdmin.password);
      formData.append('telephone', newAdmin.telephone);
      formData.append('adresse', newAdmin.adresse);
      formData.append('date_naissance', newAdmin.date_naissance);
      formData.append('role', newAdmin.role);
      formData.append('is_active', newAdmin.is_active);
      formData.append('is_staff', newAdmin.is_staff);
      formData.append('is_superuser', newAdmin.is_superuser);
      if (newAdmin.photo_profile) formData.append('photo_profile', newAdmin.photo_profile);

      const response = await fetch('http://localhost:8000/api/create-admin/', {
        method: 'POST',
        body: formData
      });
      const data = await response.json();
      if (data.status === 'success') {
        setSnackbar({ open: true, message: 'Administrateur ajouté avec succès.', severity: 'success' });
        setOpenAdd(false);
        setActiveStep(0);
        setNewAdmin({
          nom: '', email: '', password: '', telephone: '', adresse: '', date_naissance: '', photo_profile: null, is_active: true, is_staff: true, is_superuser: false, role: 'Employé'
        });
        setPhotoPreview(null);
        setAdmins(prev => [...prev, data.admin]);
      } else {
        setSnackbar({ open: true, message: data.message || 'Erreur lors de l\'ajout.', severity: 'error' });
      }
    } catch (error) {
      setSnackbar({ open: true, message: 'Erreur lors de l\'ajout.', severity: 'error' });
    }
  };

  const validateAdminFields = async (nom, email, telephone) => {
    if (!nom && !email && !telephone) {
      setErrors(prev => ({ ...prev, nom: 'Ce champ est obligatoire.', email: 'Ce champ est obligatoire.', telephone: 'Ce champ est obligatoire.' }));
      setGlobalError('');
      return;
    }
    setChecking({ nom: true, email: true, telephone: true });
    const res = await fetch('http://localhost:8000/api/check-admin-exists/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nom, email, telephone })
    });
    const data = await res.json();
    setChecking({ nom: false, email: false, telephone: false });
    const fields = Array.isArray(data.fields) ? data.fields : [];
    if (data.exists) {
      let newErrors = {};
      if (fields.includes('nom')) newErrors.nom = "Ce nom d'utilisateur est déjà utilisé.";
      if (fields.includes('email')) newErrors.email = 'Cet email est déjà utilisé par un autre utilisateur.';
      if (fields.includes('telephone')) newErrors.telephone = 'Ce téléphone est déjà utilisé par un autre utilisateur.';
      setErrors(prev => ({ ...prev, ...newErrors }));
      setGlobalError(data.message);
    } else {
      setErrors(prev => ({ ...prev, nom: '', email: '', telephone: '' }));
      setGlobalError('');
    }
  };

  // دوال مساعدة لتنسيق التاريخ والوقت
  function formatDate(dateStr) {
    if (!dateStr) return '-';
    const d = new Date(dateStr);
    if (isNaN(d)) return dateStr;
    return d.toLocaleDateString('fr-FR');
  }
  function formatDateTime(dateStr) {
    if (!dateStr) return '-';
    const d = new Date(dateStr);
    if (isNaN(d)) return dateStr;
    return d.toLocaleDateString('fr-FR') + ' ' + d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  }

  // عند الضغط على زر القلم
  const handleEditClick = (admin) => {
    setEditAdmin({ ...admin });
    setPhotoEditPreview(admin.photo_profile || null);
    setEditError('');
    setOpenEdit(true);
  };

  // عند تغيير الصورة
  const handleEditPhotoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setEditAdmin(a => ({ ...a, photo_profile: file }));
      setPhotoEditPreview(URL.createObjectURL(file));
    }
  };

  // عند حفظ التعديلات
  const handleEditSave = async () => {
    setEditLoading(true);
    setEditError('');
    try {
      const formData = new FormData();
      
      // إضافة جميع الحقول المطلوبة مع القيم الافتراضية
      formData.append('email', editAdmin.email || '');
      formData.append('telephone', editAdmin.telephone || '');
      formData.append('adresse', editAdmin.adresse || '');
      formData.append('is_active', editAdmin.is_active ? 'true' : 'false');
      formData.append('is_staff', editAdmin.is_staff ? 'true' : 'false');
      formData.append('is_superuser', editAdmin.is_superuser ? 'true' : 'false');
      
      // إضافة الصورة فقط إذا تم تغييرها
      if (editAdmin.photo_profile instanceof File) {
        formData.append('photo_profile', editAdmin.photo_profile);
      }

      const response = await fetch(`http://localhost:8000/api/administrateurs/${editAdmin.id}/update/`, {
        method: 'PATCH',
        body: formData
      });

      const data = await response.json();
      
      if (response.ok && data.status === 'success') {
        // تحديث البيانات في الواجهة مباشرة
        setAdmins(prevAdmins => 
          prevAdmins.map(admin => 
            admin.id === editAdmin.id 
              ? {
                  ...admin,
                  email: data.admin.email,
                  telephone: data.admin.telephone,
                  adresse: data.admin.adresse,
                  is_active: data.admin.is_active,
                  is_staff: data.admin.is_staff,
                  is_superuser: data.admin.is_superuser,
                  photo_profile: data.admin.photo_profile,
                  statut: data.admin.is_active ? 'Actif' : 'Inactif',
                  role: data.admin.is_superuser ? 'Directeur général' : 'Superviseur'
                }
              : admin
          )
        );

        setSnackbar({ 
          open: true, 
          message: 'Administrateur modifié avec succès.', 
          severity: 'success' 
        });
        setOpenEdit(false);
      } else {
        setEditError(data.message || 'Erreur lors de la modification.');
      }
    } catch (e) {
      console.error('Erreur de modification:', e);
      setEditError('Erreur lors de la modification.');
    } finally {
      setEditLoading(false);
    }
  };

  // دالة البحث
  const handleSearch = useCallback((query, field) => {
    if (!query.trim()) {
      setFilteredAdmins(admins);
      return;
    }

    const searchTerm = query.toLowerCase().trim();
    const filtered = admins.filter(admin => {
      switch (field) {
        case 'nom':
          return admin.nom?.toLowerCase().includes(searchTerm);
        case 'email':
          return admin.email?.toLowerCase().includes(searchTerm);
        case 'telephone':
          return admin.telephone?.toLowerCase().includes(searchTerm);
        case 'role':
          return admin.role?.toLowerCase().includes(searchTerm);
        default:
          return true;
      }
    });
    setFilteredAdmins(filtered);
  }, [admins]);

  // تحديث القائمة المفلترة عند تغيير البحث
  useEffect(() => {
    handleSearch(searchQuery, searchField);
  }, [searchQuery, searchField, handleSearch]);

  // دالة فتح مربع الحذف
  const handleDeleteClick = (admin) => {
    setAdminToDelete(admin);
    setOpenDelete(true);
  };

  // دالة تنفيذ الحذف
  const handleDeleteConfirm = async () => {
    if (!adminToDelete) return;
    setDeleteLoading(true);
    try {
      // حذف فعلي عبر API
      const response = await fetch(`http://localhost:8000/api/administrateurs/${adminToDelete.id}/delete/`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
        },
      });
      const data = await response.json();
      if (response.ok && data.status === 'success') {
        setAdmins(prev => prev.filter(a => a.id !== adminToDelete.id));
        setSnackbar({ open: true, message: 'تم حذف الإداري بنجاح.', severity: 'success' });
        setOpenDelete(false);
        setAdminToDelete(null);
      } else {
        setSnackbar({ open: true, message: data.message || 'حدث خطأ أثناء الحذف.', severity: 'error' });
      }
    } catch (e) {
      setSnackbar({ open: true, message: 'حدث خطأ أثناء الحذف.', severity: 'error' });
    } finally {
      setDeleteLoading(false);
    }
  };

  // دالة فتح نافذة الطباعة الاحترافية
  const handlePrint = () => {
    const adminsToPrint = JSON.parse(JSON.stringify(filteredAdmins));
    const printWindow = window.open('', '_blank', 'width=1200,height=800');
    printWindow.document.write(`
      <html>
      <head>
        <title>CVs du personnel administratif</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style>
          body { font-family: Arial, sans-serif; background: #f7f8fa; margin: 0; padding: 0; }
          .cv-container { max-width: 800px; margin: 32px auto; background: #fff; border-radius: 18px; box-shadow: 0 4px 32px rgba(72,97,245,0.08); padding: 36px 32px 32px 32px; position: relative; min-height: 600px; }
          .cv-header { display: flex; align-items: center; justify-content: space-between; border-bottom: 2px solid #4861F5; padding-bottom: 18px; margin-bottom: 32px; }
          .cv-logo { width: 60px; height: 60px; border-radius: 12px; }
          .cv-title { font-size: 2.1rem; font-weight: 900; color: #4861F5; margin: 0; }
          .cv-date { color: #888; font-size: 1.05rem; text-align: right; }
          .cv-profile { display: flex; align-items: center; gap: 32px; margin-bottom: 32px; }
          .cv-photo { width: 120px; height: 120px; border-radius: 50%; border: 3px solid #e3e6f5; object-fit: cover; background: #e3e6f5; display: block; }
          .cv-avatar { width: 120px; height: 120px; border-radius: 50%; background: #e3e6f5; color: #4861F5; display: flex; align-items: center; justify-content: center; font-size: 3.5rem; font-weight: 900; border: 3px solid #e3e6f5; }
          .cv-info-block { flex: 1; }
          .cv-name { font-size: 2.1rem; font-weight: 800; color: #222; margin-bottom: 6px; }
          .cv-role-badges { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
          .cv-role { font-size: 1.1rem; color: #4861F5; font-weight: 700; }
          .cv-status { display: inline-block; padding: 4px 16px; border-radius: 12px; font-weight: 700; font-size: 1rem; background: #e8f5e9; color: #2e7d32; margin-bottom: 8px; }
          .cv-status.inactive { background: #ffebee; color: #c62828; }
          .badge { display: inline-block; padding: 4px 14px; border-radius: 10px; font-weight: 700; font-size: 1rem; }
          .badge.staff { background: #e3e6f5; color: #4861F5; }
          .badge.superuser { background: #ffe0b2; color: #f57c00; }
          .cv-section { background: #f8faff; border-radius: 12px; padding: 18px 22px; margin-bottom: 18px; box-shadow: 0 1px 6px rgba(72,97,245,0.04); }
          .cv-section-title { font-size: 1.13rem; font-weight: 700; color: #4861F5; margin-bottom: 10px; display: flex; align-items: center; gap: 7px; }
          .cv-section-table { width: 100%; border-collapse: collapse; }
          .cv-section-table td { padding: 7px 0; font-size: 1.08rem; color: #444; border: none; vertical-align: top; }
          .cv-section-table .label { color: #888; font-weight: 700; width: 170px; }
          .cv-footer { margin-top: 38px; text-align: center; color: #888; font-size: 15px; }
          @media (max-width: 900px) {
            .cv-container { padding: 10px 2px; }
            .cv-title { font-size: 1.3rem; }
            .cv-name { font-size: 1.2rem; }
            .cv-photo, .cv-avatar { width: 80px; height: 80px; font-size: 2rem; }
            .cv-profile { flex-direction: column; gap: 12px; }
            .cv-section-table .label { width: 100px; }
          }
          @media print {
            .cv-container { page-break-after: always; box-shadow: none; margin: 0 auto; }
            body { background: #fff !important; }
          }
        </style>
      </head>
      <body>
        ${adminsToPrint.map((admin) => `
          <div class="cv-container">
            <div class="cv-header">
              <img src="/Tawssil_logo.png" class="cv-logo" alt="Tawssil Logo" />
              <div>
                <div class="cv-title">CV Administrateur</div>
                <div class="cv-date">Imprimé le : ${new Date().toLocaleDateString('fr-FR')} ${new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}</div>
              </div>
            </div>
            <div class="cv-profile">
              <div>
                ${admin.photo_profile ? `<img class='cv-photo' src='${admin.photo_profile}' alt='${admin.nom}' />` : `<div class='cv-avatar'>${admin.nom ? admin.nom[0] : '-'}</div>`}
              </div>
              <div class="cv-info-block">
                <div class="cv-name">${admin.nom || '-'}</div>
                <div class="cv-role-badges">
                  <span class="cv-role">${admin.role || '-'}</span>
                  ${admin.is_staff ? '<span class="badge staff">Employé (Staff)</span>' : ''}
                  ${admin.is_superuser ? '<span class="badge superuser">Super administrateur</span>' : ''}
                </div>
                <div class="cv-status${admin.is_active ? '' : ' inactive'}">${admin.is_active ? 'Actif' : 'Inactif'}</div>
              </div>
            </div>
            <div class="cv-section">
              <div class="cv-section-title">📧 Contact</div>
              <table class="cv-section-table">
                <tr><td class="label">Email :</td><td>${admin.email || '-'}</td></tr>
                <tr><td class="label">Téléphone :</td><td>${admin.telephone || '-'}</td></tr>
                <tr><td class="label">Adresse :</td><td>${admin.adresse || '-'}</td></tr>
              </table>
            </div>
            <div class="cv-section">
              <div class="cv-section-title">🗓️ Compte</div>
              <table class="cv-section-table">
                <tr><td class="label">Date de naissance :</td><td>${admin.date_naissance || '-'}</td></tr>
                <tr><td class="label">Date de création :</td><td>${admin.date_creation || '-'}</td></tr>
                <tr><td class="label">Dernière connexion :</td><td>${admin.last_login || '-'}</td></tr>
                <tr><td class="label">Dernière modification :</td><td>${admin.last_modified || '-'}</td></tr>
                ${admin.photo_profile ? `<tr><td class="label">Photo de profil :</td><td><a href='${admin.photo_profile}' target='_blank'>Voir la photo</a></td></tr>` : ''}
              </table>
            </div>
            <div class="cv-section">
              <div class="cv-section-title">🔑 Privilèges</div>
              <table class="cv-section-table">
                <tr><td class="label">Est staff :</td><td>${admin.is_staff ? 'Oui' : 'Non'}</td></tr>
                <tr><td class="label">Est superuser :</td><td>${admin.is_superuser ? 'Oui' : 'Non'}</td></tr>
              </table>
            </div>
            <div class="cv-footer">Document généré automatiquement par le système. &copy; ${new Date().getFullYear()} Tawssil</div>
          </div>
        `).join('')}
      </body>
      </html>
    `);
    printWindow.document.close();
  };

  return (
    <Box className="admin-workers-page" sx={{ bgcolor: '#f7f8fa', minHeight: '100vh', p: { xs: 1, md: 3 } }}>
      <Box display="flex" alignItems="center" justifyContent="space-between" mb={3}>
        <Box display="flex" alignItems="center" gap={1}>
          <AdminPanelSettingsIcon color="primary" fontSize="large" />
          <Typography variant="h4" fontWeight={700}>Personnel administratif</Typography>
        </Box>
        <Box display="flex" gap={2}>
          <Button variant="outlined" color="secondary" onClick={handlePrint} startIcon={<PrintIcon />}>
            Imprimer
          </Button>
          <Button variant="contained" color="primary" startIcon={<AddCircleIcon />} onClick={() => setOpenAdd(true)}>
            Ajouter un membre
          </Button>
        </Box>
      </Box>

      {/* شريط البحث المحسن */}
      <Card 
        sx={{ 
          mb: 3, 
          p: 2, 
          borderRadius: 2, 
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
          background: 'linear-gradient(to right, #ffffff, #f8faff)',
          border: '1px solid rgba(72,97,245,0.1)'
        }}
      >
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={5}>
            <TextField
              fullWidth
              variant="outlined"
              placeholder="Rechercher un administrateur..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon sx={{ color: '#4861F5' }} />
                  </InputAdornment>
                ),
                sx: {
                  '& .MuiOutlinedInput-root': {
                    '&:hover fieldset': {
                      borderColor: '#4861F5',
                    },
                  },
                }
              }}
              sx={{
                '& .MuiOutlinedInput-root': {
                  borderRadius: 2,
                  backgroundColor: 'rgba(255,255,255,0.9)',
                }
              }}
            />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField
              select
              fullWidth
              variant="outlined"
              value={searchField}
              onChange={(e) => setSearchField(e.target.value)}
              label="Rechercher par"
              sx={{
                '& .MuiOutlinedInput-root': {
                  borderRadius: 2,
                  backgroundColor: 'rgba(255,255,255,0.9)',
                }
              }}
            >
              <MenuItem value="nom">
                <Box display="flex" alignItems="center" gap={1}>
                  <PersonIcon fontSize="small" sx={{ color: '#4861F5' }} />
                  <Typography>Nom</Typography>
                </Box>
              </MenuItem>
              <MenuItem value="email">
                <Box display="flex" alignItems="center" gap={1}>
                  <EmailIcon fontSize="small" sx={{ color: '#4861F5' }} />
                  <Typography>Email</Typography>
                </Box>
              </MenuItem>
              <MenuItem value="telephone">
                <Box display="flex" alignItems="center" gap={1}>
                  <PhoneIcon fontSize="small" sx={{ color: '#4861F5' }} />
                  <Typography>Téléphone</Typography>
                </Box>
              </MenuItem>
              <MenuItem value="role">
                <Box display="flex" alignItems="center" gap={1}>
                  <BadgeIcon fontSize="small" sx={{ color: '#4861F5' }} />
                  <Typography>Rôle</Typography>
                </Box>
              </MenuItem>
            </TextField>
          </Grid>
          <Grid item xs={12} md={3}>
            <Box display="flex" gap={2} alignItems="center" justifyContent="flex-end">
              <Chip
                label={`${filteredAdmins.length} résultat(s)`}
                color="primary"
                variant="outlined"
                sx={{ 
                  borderRadius: 2,
                  '& .MuiChip-label': { fontWeight: 600 }
                }}
              />
              <Button
                variant="outlined"
                onClick={() => {
                  setSearchQuery('');
                  setSearchField('nom');
                }}
                startIcon={<ClearIcon />}
                sx={{
                  borderRadius: 2,
                  textTransform: 'none',
                  borderColor: '#4861F5',
                  color: '#4861F5',
                  '&:hover': {
                    borderColor: '#38f9d7',
                    backgroundColor: 'rgba(56,249,215,0.1)',
                  }
                }}
              >
                Réinitialiser
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Card>

      <Card className="stat-card" sx={{ borderRadius: 3, boxShadow: 2 }}>
        <CardContent>
          <TableContainer component={Paper} className="admin-workers-table" sx={{ borderRadius: 2, boxShadow: 0 }}>
            <Table sx={{ minWidth: 400 }}>
              <TableHead>
                <TableRow sx={{ bgcolor: '#f0f4ff' }}>
                  <TableCell>Nom</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Rôle</TableCell>
                  <TableCell>Téléphone</TableCell>
                  <TableCell>Adresse</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredAdmins.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} align="center">
                      <Typography color="textSecondary" py={3}>
                        {searchQuery ? 'Aucun résultat trouvé' : 'Aucun administrateur trouvé'}
                      </Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredAdmins.map(admin => (
                    <TableRow key={admin.id} hover sx={{ transition: 'background 0.2s', '&:hover': { background: '#f5f7fa' } }}>
                      <TableCell>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Avatar sx={{ width: 32, height: 32, bgcolor: '#e3e6f5', color: '#4861F5', fontWeight: 700 }}>
                            {admin.nom ? admin.nom[0] : '-'}
                          </Avatar>
                          <Typography fontWeight={600}>{admin.nom || <span style={{ color: '#bbb' }}>-</span>}</Typography>
                        </Box>
                      </TableCell>
                      <TableCell>{admin.email || <span style={{ color: '#bbb' }}>-</span>}</TableCell>
                      <TableCell>
                        <Box display="flex" alignItems="center" gap={1}>
                          {roleIcons[admin.role] || <PersonIcon color="action" fontSize="small" />}
                          <Typography>{admin.role || <span style={{ color: '#bbb' }}>-</span>}</Typography>
                        </Box>
                      </TableCell>
                      <TableCell>{admin.telephone || <span style={{ color: '#bbb' }}>-</span>}</TableCell>
                      <TableCell>{admin.adresse || <span style={{ color: '#bbb' }}>-</span>}</TableCell>
                      <TableCell>{admin.date_creation || <span style={{ color: '#bbb' }}>-</span>}</TableCell>
                      <TableCell>
                        <Chip
                          label={admin.is_active ? 'Actif' : 'Inactif'}
                          sx={{
                            bgcolor: admin.is_active ? '#e8f5e9' : '#ffebee',
                            color: admin.is_active ? '#2e7d32' : '#c62828',
                            fontWeight: 600
                          }}
                        />
                      </TableCell>
                      <TableCell align="center">
                        <IconButton color="info" onClick={() => { setSelectedAdmin(admin); setOpenDetails(true); }}><VisibilityIcon /></IconButton>
                        <IconButton color="primary" onClick={() => handleEditClick(admin)}><EditIcon /></IconButton>
                        <IconButton color="error" onClick={() => handleDeleteClick(admin)}><DeleteIcon /></IconButton>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
      {/* Dialog إضافة موظف جديد */}
      <Dialog open={openAdd} onClose={() => setOpenAdd(false)} maxWidth="sm" fullWidth PaperProps={{
        sx: {
          borderRadius: 5,
          backdropFilter: 'blur(12px)',
          background: 'rgba(255,255,255,0.85)',
          boxShadow: 8,
          border: '1.5px solid #e3e6f5',
        }
      }}>
        <DialogTitle sx={{ fontWeight: 700, fontSize: 22, display: 'flex', alignItems: 'center', gap: 1, bgcolor: 'transparent' }}>
          <AddCircleIcon color="primary" sx={{ fontSize: 28 }} /> Ajouter un membre administratif
        </DialogTitle>
        <DialogContent dividers sx={{ bgcolor: 'transparent', p: 0 }}>
          <Stepper activeStep={activeStep} alternativeLabel sx={{ mb: 3 }}>
            {steps.map(label => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>
          {activeStep === 0 && (
            <Box p={3}>
              <TextField
                label={<span>Nom complet <span style={{ color: 'red' }}>*</span></span>}
                fullWidth
                margin="normal"
                value={newAdmin.nom}
                onChange={e => {
                  setNewAdmin(a => ({ ...a, nom: e.target.value }));
                  setErrors(prev => ({ ...prev, nom: '' }));
                  setGlobalError('');
                  validateAdminFields(e.target.value, newAdmin.email, newAdmin.telephone);
                }}
                onBlur={e => validateAdminFields(e.target.value, newAdmin.email, newAdmin.telephone)}
                required
                error={!!errors.nom}
                helperText={errors.nom}
              />
              <TextField
                label={<span>Email <span style={{ color: 'red' }}>*</span></span>}
                fullWidth
                margin="normal"
                value={newAdmin.email}
                onChange={e => {
                  setNewAdmin(a => ({ ...a, email: e.target.value }));
                  setErrors(prev => ({ ...prev, email: '' }));
                  setGlobalError('');
                  validateAdminFields(newAdmin.nom, e.target.value, newAdmin.telephone);
                }}
                onBlur={e => validateAdminFields(newAdmin.nom, e.target.value, newAdmin.telephone)}
                required
                error={!!errors.email}
                helperText={errors.email}
              />
              <TextField
                label={<span>Mot de passe <span style={{ color: 'red' }}>*</span></span>}
                type="password"
                fullWidth
                margin="normal"
                value={newAdmin.password}
                onChange={e => setNewAdmin(a => ({ ...a, password: e.target.value }))}
                required
              />
              <TextField
                label={<span>Téléphone <span style={{ color: 'red' }}>*</span></span>}
                fullWidth
                margin="normal"
                value={newAdmin.telephone}
                onChange={e => {
                  setNewAdmin(a => ({ ...a, telephone: e.target.value }));
                  setErrors(prev => ({ ...prev, telephone: '' }));
                  setGlobalError('');
                  validateAdminFields(newAdmin.nom, newAdmin.email, e.target.value);
                }}
                onBlur={e => validateAdminFields(newAdmin.nom, newAdmin.email, e.target.value)}
                required
                error={!!errors.telephone}
                helperText={errors.telephone}
              />
              <Box display="flex" justifyContent="flex-end" mt={2}>
                <Button
                  variant="contained"
                  color="primary"
                  onClick={() => setActiveStep(1)}
                  disabled={
                    !newAdmin.nom || !newAdmin.email || !newAdmin.password || !newAdmin.telephone ||
                    !!errors.nom || !!errors.email || !!errors.telephone || checking.nom || checking.email || checking.telephone || globalError
                  }
                >
                  Suivant
                </Button>
              </Box>
            </Box>
          )}
          {activeStep === 1 && (
            <Box p={3}>
              <TextField
                label="Adresse"
                fullWidth
                margin="normal"
                value={newAdmin.adresse}
                onChange={e => setNewAdmin(a => ({ ...a, adresse: e.target.value }))}
              />
              <TextField
                label="Date de naissance"
                type="date"
                fullWidth
                margin="normal"
                InputLabelProps={{ shrink: true }}
                value={newAdmin.date_naissance}
                onChange={e => setNewAdmin(a => ({ ...a, date_naissance: e.target.value }))}
              />
              <Box my={2} display="flex" flexDirection="column" alignItems="center" justifyContent="center">
                <Typography variant="body2" fontWeight={600} mb={1}>Photo de profil</Typography>
                <Box
                  sx={{
                    width: 110,
                    height: 110,
                    borderRadius: '50%',
                    border: '2px dashed #bdbdbd',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    bgcolor: '#f7f8fa',
                    cursor: 'pointer',
                    position: 'relative',
                    boxShadow: 3,
                    mb: 2
                  }}
                  onClick={() => document.getElementById('photo-profile-upload').click()}
                  onDrop={e => {
                    e.preventDefault();
                    const file = e.dataTransfer.files[0];
                    setNewAdmin(a => ({ ...a, photo_profile: file }));
                    setPhotoPreview(file ? URL.createObjectURL(file) : null);
                  }}
                  onDragOver={e => e.preventDefault()}
                >
                  {photoPreview ? (
                    <Avatar src={photoPreview} sx={{ width: 100, height: 100, boxShadow: 2 }} />
                  ) : (
                    <CloudUploadIcon sx={{ fontSize: 40, color: '#bdbdbd' }} />
                  )}
                  <input
                    accept="image/*"
                    type="file"
                    style={{ display: 'none' }}
                    id="photo-profile-upload"
                    onChange={e => {
                      const file = e.target.files[0];
                      setNewAdmin(a => ({ ...a, photo_profile: file }));
                      setPhotoPreview(file ? URL.createObjectURL(file) : null);
                    }}
                  />
                </Box>
              </Box>
              <TextField
                label="Rôle"
                select
                fullWidth
                margin="normal"
                value={newAdmin.role}
                onChange={e => setNewAdmin(a => ({ ...a, role: e.target.value }))}
              >
                <MenuItem value="Directeur général">Directeur général</MenuItem>
                <MenuItem value="Superviseur">Superviseur</MenuItem>
                <MenuItem value="Employé">Employé</MenuItem>
              </TextField>
              <Box display="flex" alignItems="center" gap={2} mt={2}>
                <TextField
                  label="Statut"
                  select
                  value={newAdmin.is_active ? 'Actif' : 'Inactif'}
                  onChange={e => setNewAdmin(a => ({ ...a, is_active: e.target.value === 'Actif' }))}
                  sx={{ minWidth: 120 }}
                >
                  <MenuItem value="Actif">Actif</MenuItem>
                  <MenuItem value="Inactif">Inactif</MenuItem>
                </TextField>
                <TextField
                  label="Est staff"
                  select
                  value={newAdmin.is_staff ? 'Oui' : 'Non'}
                  onChange={e => setNewAdmin(a => ({ ...a, is_staff: e.target.value === 'Oui' }))}
                  sx={{ minWidth: 120 }}
                >
                  <MenuItem value="Oui">Oui</MenuItem>
                  <MenuItem value="Non">Non</MenuItem>
                </TextField>
                <TextField
                  label="Est superuser"
                  select
                  value={newAdmin.is_superuser ? 'Oui' : 'Non'}
                  onChange={e => setNewAdmin(a => ({ ...a, is_superuser: e.target.value === 'Oui' }))}
                  sx={{ minWidth: 120 }}
                >
                  <MenuItem value="Oui">Oui</MenuItem>
                  <MenuItem value="Non">Non</MenuItem>
                </TextField>
              </Box>
              <Box display="flex" justifyContent="space-between" mt={3}>
                <Button variant="outlined" color="primary" onClick={() => setActiveStep(0)}>
                  Précédent
                </Button>
                <Button
                  variant="contained"
                  color="success"
                  size="large"
                  startIcon={<CheckCircleIcon />}
                  sx={{ minWidth: 160, fontWeight: 700, background: 'linear-gradient(90deg,#43e97b 0%,#38f9d7 100%)' }}
                  onClick={handleAdd}
                  disabled={
                    !newAdmin.adresse || !newAdmin.date_naissance || !newAdmin.photo_profile ||
                    !newAdmin.role ||
                    !newAdmin.nom || !newAdmin.email || !newAdmin.password || !newAdmin.telephone ||
                    !!errors.nom || !!errors.email || !!errors.telephone || checking.nom || checking.email || checking.telephone || globalError
                  }
                >
                  Enregistrer
                </Button>
              </Box>
            </Box>
          )}
          {globalError && (
            <Box display="flex" justifyContent="center" alignItems="center" my={2}>
              <Alert
                severity="error"
                icon={<ErrorIcon sx={{ fontSize: 40, color: '#d32f2f' }} />}
                sx={{
                  minWidth: 350,
                  maxWidth: 500,
                  mx: 'auto',
                  boxShadow: 4,
                  borderRadius: 3,
                  background: 'linear-gradient(90deg,#ffeaea 0%,#fff6f6 100%)',
                  color: '#b71c1c',
                  fontWeight: 700,
                  fontSize: 18,
                  p: 2,
                  alignItems: 'center',
                  justifyContent: 'center',
                  textAlign: 'center',
                }}
                onClose={() => setGlobalError('')}
              >
                {globalError}
              </Alert>
            </Box>
          )}
          <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })}>
            <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} sx={{ width: '100%' }}>
              {snackbar.message}
            </Alert>
          </Snackbar>
        </DialogContent>
      </Dialog>
      <Dialog 
        open={openDetails} 
        onClose={() => setOpenDetails(false)} 
        maxWidth="md" 
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 4,
            overflow: 'hidden',
            boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
            background: 'linear-gradient(180deg, #ffffff 0%, #f8faff 100%)'
          }
        }}
      >
        {selectedAdmin && (
          <>
            <Box
              sx={{
                position: 'relative',
                height: 260,
                background: 'linear-gradient(135deg, #4861F5 0%, #38f9d7 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
                '&::before': {
                  content: '""',
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  background: 'url("data:image/svg+xml,%3Csvg width=\'100\' height=\'100\' viewBox=\'0 0 100 100\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z\' fill=\'%23ffffff\' fill-opacity=\'0.1\' fill-rule=\'evenodd\'/%3E%3C/svg%3E")',
                  opacity: 0.5
                }
              }}
            >
              <IconButton
                onClick={() => setOpenDetails(false)}
                sx={{
                  position: 'absolute',
                  top: 16,
                  right: 16,
                  bgcolor: 'rgba(255,255,255,0.2)',
                  backdropFilter: 'blur(8px)',
                  color: 'white',
                  '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' }
                }}
              >
                <CloseIcon />
              </IconButton>
              <Avatar
                src={selectedAdmin.photo_profile || undefined}
                sx={{
                  width: 120,
                  height: 120,
                  bgcolor: '#e3e6f5',
                  fontSize: 48,
                  border: '5px solid #fff',
                  boxShadow: '0 4px 20px rgba(0,0,0,0.15)',
                  position: 'relative',
                  zIndex: 2
                }}
              >
                {selectedAdmin.nom ? selectedAdmin.nom[0] : '-'}
              </Avatar>
            </Box>
            <Box sx={{ mt: 6, px: 4, pb: 4 }}>
              <Box sx={{ textAlign: 'center', mb: 4 }}>
                <Typography variant="h4" fontWeight={700} gutterBottom>
                  {selectedAdmin.nom}
                </Typography>
                <Chip
                  label={selectedAdmin.role}
                  icon={roleIcons[selectedAdmin.role]}
                  sx={{
                    px: 2,
                    py: 1,
                    fontSize: '1rem',
                    fontWeight: 600,
                    bgcolor: selectedAdmin.role === 'Directeur général' ? '#e3e6f5' : 
                             selectedAdmin.role === 'Superviseur' ? '#e8f5e9' : '#fff3e0',
                    color: selectedAdmin.role === 'Directeur général' ? '#4861F5' : 
                           selectedAdmin.role === 'Superviseur' ? '#2e7d32' : '#f57c00',
                    '& .MuiChip-icon': {
                      color: 'inherit'
                    }
                  }}
                />
              </Box>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(72,97,245,0.03)',
                      border: '1px solid rgba(72,97,245,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(72,97,245,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <EmailIcon sx={{ color: '#4861F5', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Email
                      </Typography>
                    </Box>
                    <Typography variant="body1" color="text.primary">
                      {selectedAdmin.email || '-'}
                    </Typography>
                  </Paper>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(56,249,215,0.03)',
                      border: '1px solid rgba(56,249,215,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(56,249,215,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <PhoneIcon sx={{ color: '#38f9d7', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Téléphone
                      </Typography>
                    </Box>
                    <Typography variant="body1" color="text.primary">
                      {selectedAdmin.telephone || '-'}
                    </Typography>
                  </Paper>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(255,152,0,0.03)',
                      border: '1px solid rgba(255,152,0,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(255,152,0,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <HomeIcon sx={{ color: '#ff9800', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Adresse
                      </Typography>
                    </Box>
                    <Typography variant="body1" color="text.primary">
                      {selectedAdmin.adresse || '-'}
                    </Typography>
                  </Paper>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(46,125,50,0.03)',
                      border: '1px solid rgba(46,125,50,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(46,125,50,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <CalendarMonthIcon sx={{ color: '#2e7d32', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Date de création
                      </Typography>
                    </Box>
                    <Typography variant="body1" color="text.primary">
                      {selectedAdmin.date_creation || '-'}
                    </Typography>
                  </Paper>
                </Grid>
                <Grid item xs={12}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(72,97,245,0.03)',
                      border: '1px solid rgba(72,97,245,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(72,97,245,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <BadgeIcon sx={{ color: '#4861F5', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Statut
                      </Typography>
                    </Box>
                    <Chip
                      label={selectedAdmin.is_active ? 'Actif' : 'Inactif'}
                      sx={{
                        bgcolor: selectedAdmin.is_active ? '#e8f5e9' : '#ffebee',
                        color: selectedAdmin.is_active ? '#2e7d32' : '#c62828',
                        fontWeight: 600
                      }}
                    />
                  </Paper>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(156,39,176,0.03)',
                      border: '1px solid rgba(156,39,176,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(156,39,176,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <AdminPanelSettingsIcon sx={{ color: '#9c27b0', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Privilèges du système
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      <Chip
                        label="Employé"
                        icon={<PersonIcon />}
                        sx={{
                          bgcolor: selectedAdmin.is_staff ? '#e8eaf6' : '#f5f5f5',
                          color: selectedAdmin.is_staff ? '#3f51b5' : '#9e9e9e',
                          fontWeight: 600
                        }}
                      />
                      <Chip
                        label="Super administrateur"
                        icon={<SupervisorAccountIcon />}
                        sx={{
                          bgcolor: selectedAdmin.is_superuser ? '#e8eaf6' : '#f5f5f5',
                          color: selectedAdmin.is_superuser ? '#3f51b5' : '#9e9e9e',
                          fontWeight: 600
                        }}
                      />
                    </Box>
                  </Paper>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(233,30,99,0.03)',
                      border: '1px solid rgba(233,30,99,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(233,30,99,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <CalendarMonthIcon sx={{ color: '#e91e63', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Date de naissance
                      </Typography>
                    </Box>
                    <Typography variant="body1" color="text.primary">
                      {formatDate(selectedAdmin.date_naissance)}
                    </Typography>
                  </Paper>
                </Grid>
                <Grid item xs={12}>
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3,
                      borderRadius: 3,
                      bgcolor: 'rgba(0,150,136,0.03)',
                      border: '1px solid rgba(0,150,136,0.1)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 4px 20px rgba(0,150,136,0.1)'
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <AccessTimeIcon sx={{ color: '#009688', mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
                        Informations du compte
                      </Typography>
                    </Box>
                    <Grid container spacing={2}>
                      <Grid item xs={12} sm={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body2" color="text.secondary">Dernière connexion :</Typography>
                          <Typography variant="body2" color="text.primary">
                            {formatDateTime(selectedAdmin.last_login)}
                          </Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={12} sm={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body2" color="text.secondary">Date de création :</Typography>
                          <Typography variant="body2" color="text.primary">
                            {formatDateTime(selectedAdmin.date_creation)}
                          </Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={12} sm={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body2" color="text.secondary">Dernière modification :</Typography>
                          <Typography variant="body2" color="text.primary">
                            {formatDateTime(selectedAdmin.last_modified)}
                          </Typography>
                        </Box>
                      </Grid>
                    </Grid>
                  </Paper>
                </Grid>
              </Grid>
            </Box>
          </>
        )}
      </Dialog>
      <Dialog open={openEdit} onClose={() => setOpenEdit(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: 5, overflow: 'hidden', boxShadow: 8 } }}>
        <Box sx={{
          background: 'linear-gradient(135deg, #4861F5 0%, #38f9d7 100%)',
          p: 4,
          position: 'relative',
          textAlign: 'center',
          minHeight: 180
        }}>
          <IconButton
            onClick={() => setOpenEdit(false)}
            sx={{
              position: 'absolute',
              top: 16,
              right: 16,
              bgcolor: 'rgba(255,255,255,0.2)',
              color: 'white',
              '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' }
            }}
          >
            <CloseIcon />
          </IconButton>
          <Box sx={{ position: 'relative', display: 'inline-block', mb: -8 }}>
            <Avatar
              src={photoEditPreview || undefined}
              sx={{ width: 110, height: 110, mx: 'auto', boxShadow: 3, border: '4px solid #fff', bgcolor: '#e3e6f5', fontSize: 40 }}
            >
              {editAdmin?.nom ? editAdmin.nom[0] : '-'}
            </Avatar>
            <input
              accept="image/*"
              type="file"
              style={{ display: 'none' }}
              id="edit-photo-upload"
              onChange={handleEditPhotoChange}
            />
            <IconButton
              component="span"
              sx={{
                position: 'absolute',
                bottom: 0,
                right: 0,
                bgcolor: '#4861F5',
                color: 'white',
                border: '2px solid #fff',
                boxShadow: 2,
                '&:hover': { bgcolor: '#38f9d7', color: '#4861F5' },
                zIndex: 2
              }}
              onClick={() => document.getElementById('edit-photo-upload').click()}
            >
              <CloudUploadIcon />
            </IconButton>
          </Box>
          <Typography variant="h5" fontWeight={700} color="white" mt={2} mb={0.5}>
            {editAdmin?.nom}
          </Typography>
          <Typography variant="subtitle1" color="#e0e0e0">
            Modifier les informations de l'administrateur
          </Typography>
        </Box>
        <DialogContent sx={{ bgcolor: '#fafdff', p: 4 }}>
          {editAdmin && (
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <TextField
                  label="Email"
                  fullWidth
                  margin="normal"
                  value={editAdmin.email}
                  onChange={e => setEditAdmin(a => ({ ...a, email: e.target.value }))}
                  InputProps={{ startAdornment: <EmailIcon sx={{ color: '#4861F5', mr: 1 }} /> }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  label="Téléphone"
                  fullWidth
                  margin="normal"
                  value={editAdmin.telephone}
                  onChange={e => setEditAdmin(a => ({ ...a, telephone: e.target.value }))}
                  InputProps={{ startAdornment: <PhoneIcon sx={{ color: '#38f9d7', mr: 1 }} /> }}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  label="Adresse"
                  fullWidth
                  margin="normal"
                  value={editAdmin.adresse}
                  onChange={e => setEditAdmin(a => ({ ...a, adresse: e.target.value }))}
                  InputProps={{ startAdornment: <HomeIcon sx={{ color: '#ff9800', mr: 1 }} /> }}
                />
              </Grid>
              <Grid item xs={12} container spacing={2}>
                <Grid item xs={12} md={4}>
                  <TextField
                    label="Statut"
                    select
                    fullWidth
                    margin="normal"
                    value={editAdmin.is_active ? 'Actif' : 'Inactif'}
                    onChange={e => setEditAdmin(a => ({ ...a, is_active: e.target.value === 'Actif' }))}
                  >
                    <MenuItem value="Actif">Actif</MenuItem>
                    <MenuItem value="Inactif">Inactif</MenuItem>
                  </TextField>
                </Grid>
                <Grid item xs={12} md={4}>
                  <TextField
                    label="Employé"
                    select
                    fullWidth
                    margin="normal"
                    value={editAdmin.is_staff ? 'Oui' : 'Non'}
                    onChange={e => setEditAdmin(a => ({ ...a, is_staff: e.target.value === 'Oui' }))}
                  >
                    <MenuItem value="Oui">Oui</MenuItem>
                    <MenuItem value="Non">Non</MenuItem>
                  </TextField>
                </Grid>
                <Grid item xs={12} md={4}>
                  <TextField
                    label="Super administrateur"
                    select
                    fullWidth
                    margin="normal"
                    value={editAdmin.is_superuser ? 'Oui' : 'Non'}
                    onChange={e => setEditAdmin(a => ({ ...a, is_superuser: e.target.value === 'Oui' }))}
                  >
                    <MenuItem value="Oui">Oui</MenuItem>
                    <MenuItem value="Non">Non</MenuItem>
                  </TextField>
                </Grid>
              </Grid>
              {editError && <Grid item xs={12}><Alert severity="error">{editError}</Alert></Grid>}
              <Grid item xs={12}>
                <Box display="flex" justifyContent="flex-end" gap={2} mt={2}>
                  <Button onClick={() => setOpenEdit(false)} color="secondary" variant="outlined">ANNULER</Button>
                  <Button onClick={handleEditSave} color="primary" variant="contained" disabled={editLoading} sx={{ minWidth: 140 }}>
                    {editLoading ? 'ENREGISTREMENT...' : 'ENREGISTRER'}
                  </Button>
                </Box>
              </Grid>
            </Grid>
          )}
        </DialogContent>
      </Dialog>
      {/* مربع حوار الحذف */}
      <Dialog open={openDelete} onClose={() => setOpenDelete(false)} maxWidth="xs" fullWidth PaperProps={{ sx: { borderRadius: 4, boxShadow: 8 } }}>
        <Box sx={{ p: 4, textAlign: 'center', bgcolor: 'linear-gradient(135deg,#fffbe7 0%,#fff 100%)' }}>
          <WarningAmberIcon sx={{ fontSize: 60, color: '#ff9800', mb: 2 }} />
          <Alert severity="warning" icon={false} sx={{
            mb: 2,
            fontWeight: 700,
            fontSize: 18,
            bgcolor: 'rgba(255,152,0,0.08)',
            color: '#b26a00',
            border: '1.5px solid #ffe0b2',
            borderRadius: 2,
            boxShadow: 2
          }}>
            Êtes-vous sûr de vouloir supprimer le compte administrateur <span style={{color:'#d84315'}}>{adminToDelete?.nom}</span> ?<br/>
            Cette action est irréversible !
          </Alert>
          <Box display="flex" justifyContent="center" gap={2} mt={2}>
            <Button variant="outlined" color="primary" onClick={() => setOpenDelete(false)} disabled={deleteLoading} sx={{ minWidth: 100, borderRadius: 2 }}>Annuler</Button>
            <Button variant="contained" color="error" onClick={handleDeleteConfirm} disabled={deleteLoading} sx={{ minWidth: 120, borderRadius: 2, fontWeight: 700 }}>
              {deleteLoading ? 'Suppression...' : 'Confirmer la suppression'}
            </Button>
          </Box>
        </Box>
      </Dialog>
    </Box>
  );
};

export default AdminWorkers; 