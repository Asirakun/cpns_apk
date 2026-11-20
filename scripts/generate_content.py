"""Original template-based practice content. Requires subject-matter review before production."""
import json,random,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
rng=random.Random(20261120)
questions=[]
def add(domain,topic,text,options,correct=None,explanation='',scores=None,diagram=None):
    order=list(range(5)); rng.shuffle(order)
    q={'id':f'{domain.lower()}-{sum(q["domain"]==domain for q in questions)+1:03d}','domain':domain,'topic':topic,'text':text,'options':[{'id':chr(65+i),'text':options[j],'score':scores[j] if scores else (5 if j==correct else 0)} for i,j in enumerate(order)],'explanation':explanation,'version':1,'level':'dasar' if len(questions)%3 else 'menengah','license':'CC BY 4.0 — CPNS Journey, original generated practice','publication_status':'published','review_status':'automated_validation_only','reviewer':'content-validator-v1','diagram':diagram}
    questions.append(q)
facts=[
('Pancasila','Sila yang menegaskan persatuan bangsa adalah','Persatuan Indonesia',['Kemanusiaan yang adil dan beradab','Ketuhanan Yang Maha Esa','Keadilan sosial bagi seluruh rakyat Indonesia','Kerakyatan yang dipimpin oleh hikmat kebijaksanaan dalam permusyawaratan/perwakilan'],'Sila ketiga menempatkan persatuan Indonesia sebagai dasar hidup berbangsa.'),
('Pancasila','Menghormati rekan yang menjalankan ibadah mencerminkan terutama sila','Ketuhanan Yang Maha Esa',['Persatuan Indonesia','Keadilan sosial','Kerakyatan','Tidak ada sila yang relevan'],'Sila pertama menjadi dasar penghormatan kebebasan beragama dan beribadah.'),
('Pancasila','Musyawarah untuk menentukan keputusan bersama paling dekat dengan sila','Keempat',['Pertama','Kedua','Ketiga','Kelima'],'Sila keempat menekankan hikmat kebijaksanaan dalam permusyawaratan/perwakilan.'),
('Pancasila','Memberikan layanan tanpa diskriminasi mencerminkan nilai','Kemanusiaan yang adil dan beradab',['Dominasi mayoritas','Kepentingan kelompok','Keistimewaan keluarga','Keseragaman keyakinan'],'Pengakuan martabat manusia menjadi landasan layanan yang adil.'),
('Pancasila','Pemerataan kesempatan memperoleh layanan publik sejalan dengan sila','Kelima',['Pertama saja','Kedua saja','Ketiga saja','Keempat saja'],'Keadilan sosial mendorong distribusi kesempatan dan layanan secara adil.'),
('Konstitusi','Dasar konstitusional negara Indonesia adalah','UUD Negara Republik Indonesia Tahun 1945',['Peraturan desa','Surat edaran','Keputusan rapat organisasi','Tata tertib kantor'],'UUD NRI Tahun 1945 merupakan konstitusi Indonesia.'),
('Konstitusi','Menurut Pasal 1 ayat (3) UUD 1945, Indonesia adalah negara','Hukum',['Kekuasaan mutlak','Federasi','Monarki','Serikat'],'Pasal 1 ayat (3) menyatakan Negara Indonesia adalah negara hukum.'),
('Konstitusi','Bentuk negara Indonesia menurut Pasal 1 ayat (1) UUD 1945 adalah','Kesatuan',['Federasi','Konfederasi','Serikat','Persemakmuran'],'Indonesia ialah negara kesatuan yang berbentuk republik.'),
('Konstitusi','Kedaulatan berada di tangan rakyat dan dilaksanakan menurut','Undang-Undang Dasar',['Kehendak satu pejabat','Kebiasaan pribadi','Keputusan partai tunggal','Perintah perusahaan'],'Pasal 1 ayat (2) UUD 1945 menetapkan pelaksanaan kedaulatan menurut UUD.'),
('Konstitusi','Lembaga yang berwenang mengubah dan menetapkan UUD adalah','MPR',['DPRD','KPU','BPK','Komisi Yudisial'],'Kewenangan MPR diatur dalam Pasal 3 ayat (1) UUD 1945.'),
('Konstitusi','Presiden memegang kekuasaan pemerintahan menurut','UUD',['Keputusan organisasi privat','Instruksi perusahaan','Surat pribadi','Kebiasaan lokal saja'],'Pasal 4 ayat (1) UUD 1945 mengatur kekuasaan pemerintahan Presiden.'),
('Konstitusi','Lembaga yang memegang kekuasaan membentuk undang-undang adalah','DPR',['BPK','KPU','BNPB','KPK'],'Pasal 20 ayat (1) UUD 1945 menetapkan kekuasaan membentuk UU pada DPR.'),
('Konstitusi','Lembaga yang memeriksa pengelolaan dan tanggung jawab keuangan negara adalah','BPK',['KPU','DPD','MPR','Komisi Yudisial'],'BPK diatur dalam Pasal 23E UUD 1945.'),
('Konstitusi','Pengujian undang-undang terhadap UUD dilakukan oleh','Mahkamah Konstitusi',['DPRD','Kementerian Keuangan','BPK','KPU'],'Kewenangan tersebut merupakan salah satu kewenangan MK menurut Pasal 24C.'),
('Konstitusi','Pemilihan umum menurut UUD dilaksanakan setiap','Lima tahun',['Dua tahun','Tiga tahun','Empat tahun','Tujuh tahun'],'Pasal 22E ayat (1) mengatur pemilu setiap lima tahun.'),
('Konstitusi','Asas pemilu mencakup langsung, umum, bebas, rahasia, jujur, dan','Adil',['Tertutup','Berbayar','Eksklusif','Terbatas'],'Enam asas pemilu dikenal sebagai luber dan jurdil.'),
('Konstitusi','Bendera negara Indonesia adalah','Sang Merah Putih',['Bintang Merah','Merah Biru','Putih Hijau','Garuda Biru'],'Pasal 35 UUD 1945 menyebut bendera negara Sang Merah Putih.'),
('Konstitusi','Bahasa negara Indonesia adalah','Bahasa Indonesia',['Bahasa daerah terbesar','Bahasa Inggris','Bahasa Belanda','Bahasa organisasi'],'Pasal 36 UUD 1945 menetapkan bahasa negara ialah Bahasa Indonesia.'),
('Konstitusi','Lambang negara Indonesia adalah','Garuda Pancasila',['Banteng Merah','Pohon Beringin saja','Bintang Tunggal saja','Padi Kapas saja'],'Pasal 36A mengatur Garuda Pancasila dengan semboyan Bhinneka Tunggal Ika.'),
('Konstitusi','Lagu kebangsaan Indonesia adalah','Indonesia Raya',['Bagimu Negeri','Hari Merdeka','Garuda Pancasila','Tanah Airku'],'Pasal 36B UUD 1945 menetapkan lagu kebangsaan Indonesia Raya.'),
('Nasionalisme','Makna Bhinneka Tunggal Ika yang tepat adalah','Berbeda-beda tetapi tetap satu',['Semua perbedaan harus dihapus','Hanya satu budaya yang diakui','Kelompok terbesar selalu benar','Perbedaan membenarkan diskriminasi'],'Semboyan ini mengakui keragaman dalam kesatuan bangsa.'),
('Nasionalisme','Sumpah Pemuda diperingati setiap tanggal','28 Oktober',['17 Agustus','1 Juni','20 Mei','10 November'],'Kongres Pemuda II melahirkan Sumpah Pemuda pada 28 Oktober 1928.'),
('Nasionalisme','Hari Kebangkitan Nasional diperingati setiap tanggal','20 Mei',['1 Juni','28 Oktober','17 Agustus','10 November'],'Peringatan terkait berdirinya Budi Utomo pada 20 Mei 1908.'),
('Nasionalisme','Hari Lahir Pancasila diperingati setiap tanggal','1 Juni',['20 Mei','28 Oktober','10 November','21 April'],'Tanggal 1 Juni diperingati sebagai Hari Lahir Pancasila.'),
('Nasionalisme','Proklamasi kemerdekaan Indonesia berlangsung pada','17 Agustus 1945',['1 Juni 1945','28 Oktober 1928','20 Mei 1908','10 November 1945'],'Proklamasi dibacakan pada 17 Agustus 1945.'),
('Nasionalisme','Tokoh yang mendampingi Soekarno saat pembacaan proklamasi adalah','Mohammad Hatta',['Ki Hadjar Dewantara','Sutan Sjahrir','Mohammad Yamin','Soepomo'],'Proklamasi ditandatangani Soekarno-Hatta atas nama bangsa Indonesia.'),
('Nasionalisme','Wawasan Nusantara memandang wilayah Indonesia sebagai','Satu kesatuan bangsa dan wilayah',['Sekumpulan negara terpisah','Wilayah tanpa ikatan hukum','Kepentingan satu pulau','Kota-kota yang berdiri sendiri'],'Wawasan Nusantara menekankan kesatuan wilayah dan kehidupan nasional.'),
('Nasionalisme','Sikap yang mendukung persatuan adalah','Menghormati perbedaan suku dan budaya',['Menolak teman berbeda suku','Menyebar stereotip','Membatasi layanan berdasarkan asal','Memaksakan bahasa daerah pada semua layanan'],'Penghormatan terhadap keragaman memperkuat persatuan.'),
('Bela negara','Bela negara dapat dilakukan warga sipil dengan','Menjalankan kewajiban dan menjaga persatuan',['Melakukan kekerasan pada kritik','Menyebar kabar tanpa cek','Menolak aturan hukum','Mengutamakan konflik kelompok'],'Bela negara mencakup kontribusi sesuai profesi dan ketaatan pada hukum.'),
('Bela negara','Sikap tepat terhadap kabar provokatif yang belum jelas adalah','Memverifikasi sumber sebelum menyebarkan',['Langsung meneruskan','Menambah narasi emosional','Membuka data pribadi orang lain','Menganggap viral berarti benar'],'Verifikasi membantu mencegah hoaks dan konflik sosial.'),
('Integritas','Integritas aparatur ditunjukkan oleh','Konsisten antara nilai, ucapan, dan tindakan',['Mengubah laporan agar terlihat baik','Menyembunyikan kesalahan','Mendahulukan keluarga','Menerima hadiah karena jabatan'],'Konsistensi dan kejujuran merupakan unsur utama integritas.'),
('Integritas','Benturan kepentingan perlu ditangani dengan','Mengungkapkan hubungan yang relevan dan mengikuti prosedur',['Menyembunyikan hubungan','Memutuskan sendiri untuk kerabat','Menghapus catatan','Memindahkan tanggung jawab diam-diam'],'Transparansi dan pengelolaan konflik kepentingan menjaga objektivitas.'),
('Integritas','Ketika mengetahui kesalahan laporan, tindakan berintegritas adalah','Memperbaiki dengan jejak koreksi sesuai prosedur',['Menghapus seluruh riwayat','Menyalahkan staf lain','Membiarkan karena sudah dikirim','Mengubah angka tanpa keterangan'],'Koreksi yang terdokumentasi menjaga akuntabilitas.'),
('Pelayanan publik','Tujuan utama pelayanan publik adalah','Memenuhi kebutuhan masyarakat sesuai ketentuan',['Mendahulukan pemberi hadiah','Menyulitkan pemohon','Menguntungkan petugas','Membatasi akses tanpa alasan'],'Layanan publik berorientasi pada kebutuhan masyarakat dan aturan.'),
('Pelayanan publik','Prinsip akuntabilitas berarti','Keputusan dan tindakan dapat dipertanggungjawabkan',['Semua data harus dirahasiakan tanpa dasar','Petugas bebas dari evaluasi','Proses tidak perlu dicatat','Hasil menghapus kebutuhan prosedur'],'Akuntabilitas membutuhkan tanggung jawab dan bukti proses.'),
('Pelayanan publik','Standar layanan membantu masyarakat mengetahui','Syarat, proses, waktu, dan biaya yang berlaku',['Cara memberikan uang pribadi','Identitas keluarga petugas','Rahasia kata sandi','Pilihan politik pegawai'],'Standar layanan memberi kejelasan prosedur dan kepastian.'),
('Bahasa Indonesia','Bentuk baku yang tepat adalah','Risiko',['Resiko','Ressiko','Riziko','Riskho'],'Bentuk baku dalam bahasa Indonesia adalah risiko.'),
('Bahasa Indonesia','Bentuk baku untuk kegiatan penerapan adalah','Praktik',['Praktek','Prakteq','Praktick','Peraktek'],'Bentuk baku adalah praktik; verba turunannya mempraktikkan.'),
('Bahasa Indonesia','Penulisan kata depan yang tepat adalah','Di kantor',['Dikantor','diKantor','Di-kantor','D i kantor'],'Kata depan di ditulis terpisah dari kata yang mengikutinya.'),
('Bahasa Indonesia','Penulisan imbuhan yang tepat adalah','Dikerjakan',['Di kerjakan','Di-kerjakan','D i kerjakan','Dikerja kan'],'Awalan di- pada verba pasif ditulis serangkai.'),
('Bahasa Indonesia','Kalimat efektif mengutamakan','Kejelasan, ketepatan, dan kehematan',['Pengulangan sebanyak mungkin','Istilah asing tanpa kebutuhan','Subjek yang kabur','Makna ganda yang disengaja'],'Kalimat efektif menyampaikan gagasan secara jelas dan hemat.'),
('Konstitusi','Hak memperoleh pendidikan diatur terutama dalam Pasal','31 UUD 1945',['1 UUD 1945','4 UUD 1945','35 UUD 1945','36B UUD 1945'],'Pasal 31 memuat ketentuan tentang pendidikan.'),
('Konstitusi','Perekonomian disusun sebagai usaha bersama berdasarkan asas','Kekeluargaan',['Monopoli pribadi','Diskriminasi','Kerahasiaan total','Kepentingan perseorangan saja'],'Pasal 33 ayat (1) UUD 1945 menggunakan asas kekeluargaan.'),
('Konstitusi','Fakir miskin dan anak-anak terlantar dipelihara oleh','Negara',['Perusahaan asing saja','Partai tertentu saja','Kelompok profesi saja','Pemohon sendiri tanpa dukungan'],'Pasal 34 ayat (1) UUD 1945 mengatur tanggung jawab negara.'),
('Konstitusi','Tujuan negara dalam Pembukaan UUD mencakup','Mencerdaskan kehidupan bangsa',['Membatasi pendidikan','Menghapus keragaman budaya','Mendahulukan satu golongan','Meniadakan kepastian hukum'],'Mencerdaskan kehidupan bangsa adalah salah satu tujuan negara pada alinea keempat.'),
('Demokrasi','Kritik terhadap kebijakan publik sebaiknya disampaikan secara','Bertanggung jawab dan berdasarkan fakta',['Dengan ancaman kekerasan','Dengan menyebar data pribadi','Dengan kabar palsu','Dengan diskriminasi'],'Kebebasan menyampaikan pendapat disertai tanggung jawab dan penghormatan hak orang lain.'),
('Demokrasi','Dalam musyawarah, peserta sebaiknya','Mendengarkan alasan setiap pihak',['Membungkam pendapat minoritas','Memaksa keputusan dengan ancaman','Menolak semua data','Meninggalkan rapat tanpa penjelasan'],'Musyawarah membutuhkan keterbukaan, kesetaraan, dan orientasi kepentingan bersama.'),
('Bela negara','Ketahanan informasi pribadi diperkuat dengan','Kata sandi unik dan autentikasi tambahan',['Membagikan OTP','Memakai kata sandi yang sama','Mengirim KTP ke grup umum','Mematikan semua pembaruan'],'Keamanan akun merupakan kontribusi pada ketahanan digital.'),
('Bela negara','Saat bencana, kontribusi warga yang tepat adalah','Mengikuti koordinasi petugas dan membantu sesuai kemampuan',['Menyebar lokasi palsu','Menghalangi evakuasi','Menimbun bantuan','Mengabaikan instruksi keselamatan'],'Koordinasi dan kepatuhan pada petunjuk keselamatan meningkatkan efektivitas bantuan.'),
('Nasionalisme','Cinta tanah air dapat diwujudkan melalui','Bekerja jujur dan merawat lingkungan bersama',['Mendiskriminasi pendatang','Menolak semua budaya lain','Merusak fasilitas publik','Menghindari kewajiban warga'],'Nasionalisme tampak dalam kontribusi konstruktif sehari-hari.'),
('Pelayanan publik','Perlakuan adil bagi penyandang disabilitas mencakup','Akomodasi akses sesuai kebutuhan',['Menolak semua permohonan','Meminta biaya pribadi tambahan','Menganggap semua kebutuhan sama','Mengabaikan komunikasi aksesibel'],'Kesetaraan akses memerlukan akomodasi yang sesuai kebutuhan.'),
('Integritas','Dokumentasi keputusan berguna untuk','Penelusuran alasan dan pertanggungjawaban',['Menyembunyikan proses','Menghapus pengawasan','Menggantikan seluruh aturan','Membenarkan diskriminasi'],'Dokumentasi mendukung audit dan evaluasi yang dapat dipertanggungjawabkan.'),
('Integritas','Hadiah yang berhubungan dengan jabatan sebaiknya','Ditangani sesuai ketentuan gratifikasi',['Selalu diterima diam-diam','Disembunyikan dari kantor','Dibagi agar tidak ketahuan','Dianggap pasti tidak bermasalah'],'Ikuti ketentuan penolakan atau pelaporan gratifikasi dan prosedur instansi.'),
('Nasionalisme','Gotong royong menekankan','Kerja bersama untuk kepentingan bersama',['Pemaksaan keuntungan pribadi','Persaingan tanpa aturan','Penolakan kontribusi','Pengucilan kelompok kecil'],'Gotong royong adalah kerja bersama dengan semangat saling membantu.'),
('Konstitusi','Kekuasaan kehakiman menurut UUD bersifat','Merdeka',['Di bawah kepentingan partai','Mengikuti pemberi hadiah','Tanpa dasar hukum','Bergantung pada popularitas'],'Pasal 24 ayat (1) menjamin kekuasaan kehakiman yang merdeka.'),
('Konstitusi','Presiden dan Wakil Presiden dipilih secara langsung oleh','Rakyat',['BPK','Komisi Yudisial','Seluruh perusahaan','DPRD saja'],'Pasal 6A mengatur pemilihan langsung oleh rakyat.'),
('Konstitusi','Masa jabatan Presiden dan Wakil Presiden satu periode adalah','Lima tahun',['Tiga tahun','Empat tahun','Enam tahun','Sepuluh tahun'],'Pasal 7 mengatur masa jabatan lima tahun dan dapat dipilih kembali satu kali.'),
('Bahasa Indonesia','Penulisan kata baku yang tepat adalah','Izin',['Ijin','Idzin','Izyn','Ijiin'],'Bentuk baku adalah izin.'),
('Bahasa Indonesia','Penulisan kata baku yang tepat adalah','Analisis',['Analisa','Analisys','Analisia','Analizis'],'Bentuk baku adalah analisis.'),
('Pelayanan publik','Pengaduan masyarakat sebaiknya ditangani dengan','Dicatat, diverifikasi, dan ditindaklanjuti sesuai prosedur',['Dihapus agar statistik bagus','Diabaikan bila kritis','Dibalas dengan identitas pribadi','Diminta uang agar diproses'],'Pengaduan merupakan masukan perbaikan layanan dan harus ditangani secara akuntabel.')
]
assert len(facts)==60,len(facts)
for variant in range(2):
 for topic,prompt,answer,distractors,exp in facts:
  opts=[answer]+distractors
  if variant==0: add('TWK',topic,prompt+' …',opts,0,exp)
  else:
   # Reverse recall tests a different direction, still original and deterministic.
   add('TWK',topic,f'Dalam diskusi {topic.lower()}, seorang peserta menjawab “{answer}”. Pernyataan yang paling tepat untuk jawaban tersebut adalah …',[prompt]+[x[1] for x in rng.sample([f for f in facts if f[0]!=topic],4)],0,exp)
for i in range(140):
 kind=i%7; n=i//7+2
 if kind==0:
  a=n+3; d=n%6+2; seq=[a+j*d for j in range(5)]; answer=a+5*d
  text='Tentukan angka berikutnya: '+', '.join(map(str,seq))+', …'; exp=f'Selisih tetap {d}. Angka berikutnya {seq[-1]} + {d} = {answer}.'; topic='Deret angka'
 elif kind==1:
  price=(n+3)*10000; percent=10+(n%4)*5; answer=price*(100-percent)//100
  text=f'Harga buku Rp{price:,} mendapat diskon {percent}%. Berapa harga setelah diskon (rupiah)?'; exp=f'Harga akhir = {price} × {100-percent}/100 = {answer} rupiah.'; topic='Persentase'
 elif kind==2:
  a=n+2; b=n%5+3; total=(a+b)*5; answer=a*5
  text=f'Perbandingan buku A dan B adalah {a}:{b}. Jumlahnya {total} buku. Berapa buku A?'; exp=f'Bagian A = {a}/({a}+{b}) × {total} = {answer}.'; topic='Perbandingan'
 elif kind==3:
  speed=20+n*2; t=3; answer=speed*t
  text=f'Kendaraan bergerak dengan kecepatan tetap {speed} km/jam selama {t} jam. Jaraknya (km) adalah …'; exp=f'Jarak = kecepatan × waktu = {speed} × {t} = {answer} km.'; topic='Jarak dan waktu'
 elif kind==4:
  a=n+3; b=n+8; answer=(a+b)*2
  text=f'Persegi panjang mempunyai panjang {b} cm dan lebar {a} cm. Kelilingnya (cm) adalah …'; exp=f'Keliling = 2 × ({a}+{b}) = {answer} cm.'; topic='Geometri'
 elif kind==5:
  answer=n+5; text=f'Jika 3x + {n} = {3*answer+n}, nilai x adalah …'; exp=f'3x = {3*answer+n} − {n} = {3*answer}; x = {answer}.'; topic='Aljabar'
 else:
  shapes=['○','△','□','◇','★']; offset=n%5; seq=[shapes[(j+offset)%5] for j in range(7)]; ans=shapes[(7+offset)%5]
  # Add rotation interval to provide unique visual questions.
  text=f'Pola ke-{n}: ulangi siklus {" → ".join(shapes[offset:]+shapes[:offset])}. Simbol pada posisi {n+10} adalah …'
  ans=shapes[(n+9+offset)%5]
  add('TIU','Figural',text,shapes,shapes.index(ans),f'Siklus berisi 5 simbol. Posisi {n+10} berada pada urutan {(n+9)%5+1} siklus, yaitu {ans}.',diagram=' '.join(seq)); continue
 vals=[answer,answer+1,answer+3,max(0,answer-2),answer+7]; assert len(set(vals))==5
 add('TIU',topic,text,list(map(str,vals)),0,exp)
scenarios=[
('Pelayanan publik','seorang pemohon lansia kesulitan memahami alur layanan','Menjelaskan dengan bahasa sederhana dan membantu sesuai prosedur','Mendengarkan kebutuhan lalu menunjukkan panduan yang relevan'),
('Pelayanan publik','antrean meningkat sementara satu loket mengalami gangguan','Mengatur antrean, memberi informasi, dan berkoordinasi membuka alternatif resmi','Memberikan estimasi berdasarkan informasi yang dapat dipastikan'),
('Pelayanan publik','pemohon marah karena berkasnya belum lengkap','Mendengarkan dengan tenang dan menjelaskan kekurangan serta cara melengkapinya','Menunjukkan daftar persyaratan dan menawarkan penjelasan'),
('Pelayanan publik','pengguna dengan hambatan pendengaran membutuhkan informasi','Menawarkan komunikasi tertulis atau aksesibilitas sesuai kebutuhannya','Mencari dukungan petugas yang memahami kebutuhan aksesibilitas'),
('Pelayanan publik','pemohon datang menjelang penutupan dengan urusan mendesak','Mengecek prosedur dan memberi pilihan layanan yang sah serta informasi waktu','Menerangkan jadwal dan jalur resmi yang tersedia'),
('Integritas','kerabat meminta didahulukan dari antrean','Menjelaskan aturan antrean dan mengelola potensi benturan kepentingan','Mengarahkan kerabat mengikuti jalur resmi'),
('Integritas','rekan meminta tanda tangan pada laporan yang belum diperiksa','Memeriksa bukti terlebih dahulu dan menandatangani hanya sesuai kewenangan','Meminta waktu untuk melakukan pemeriksaan'),
('Integritas','kesalahan angka ditemukan pada laporan yang telah dikirim','Melaporkan kesalahan dan membuat koreksi terdokumentasi sesuai prosedur','Segera menghubungi penanggung jawab untuk membahas koreksi'),
('Integritas','pemberi layanan menawarkan hadiah terkait pekerjaan','Menolak dengan sopan dan mengikuti prosedur gratifikasi yang berlaku','Meminta arahan unit terkait tanpa menggunakan hadiah'),
('Integritas','atasan meminta data yang tidak sesuai fakta dimasukkan ke laporan','Menjelaskan fakta dengan bukti dan menggunakan jalur eskalasi resmi bila diperlukan','Meminta klarifikasi instruksi sambil mempertahankan data yang benar'),
('Profesionalisme','tugas baru memakai sistem yang belum dikuasai','Mempelajari panduan, berlatih, dan meminta bimbingan terarah','Meminta rekan menjelaskan langkah awal sambil belajar mandiri'),
('Profesionalisme','dua tenggat pekerjaan jatuh pada hari yang sama','Memetakan urgensi, mengomunikasikan kapasitas, dan menyepakati prioritas','Menyusun daftar tugas dan mengerjakan yang paling mendesak'),
('Profesionalisme','hasil kerja dikritik dalam evaluasi','Meminta contoh konkret dan menyusun langkah perbaikan yang terukur','Mencatat kritik dan meninjau pekerjaan'),
('Profesionalisme','pedoman kerja diperbarui','Membaca perubahan, menyesuaikan proses, dan mengecek pemahaman tim','Mengikuti pengarahan dan memperbarui catatan pribadi'),
('Profesionalisme','rekap harian berulang menyita waktu','Mengusulkan perbaikan yang aman, mengujinya, dan tetap menjaga kontrol data','Membuat rancangan sederhana untuk dibahas dengan penanggung jawab'),
('Sosial budaya','tim terdiri dari latar budaya yang berbeda','Menyepakati cara komunikasi yang menghormati perbedaan dan tujuan bersama','Mendengarkan preferensi komunikasi rekan'),
('Sosial budaya','candaan rekan merendahkan asal daerah seseorang','Menghentikan dengan sopan, mendukung pihak terdampak, dan menjaga suasana inklusif','Mengajak rekan berbicara empat mata agar candaan tidak diulang'),
('Sosial budaya','jadwal kegiatan bertepatan dengan kebutuhan ibadah rekan','Mencari penyesuaian adil tanpa mengabaikan kebutuhan layanan','Mendiskusikan pertukaran jadwal secara sukarela'),
('Sosial budaya','pendatang baru belum memahami kebiasaan tim','Membantu orientasi tanpa memaksakan stereotip dan membuka ruang bertanya','Memberi panduan dasar tentang alur kerja tim'),
('Sosial budaya','perbedaan bahasa menimbulkan salah paham dengan pengguna','Menggunakan bahasa yang dipahami atau bantuan resmi dan mengonfirmasi pemahaman','Menyederhanakan kalimat dan meminta pengguna menjelaskan kembali'),
('Jejaring kerja','unit lain terlambat memberikan data yang dibutuhkan','Mengklarifikasi hambatan, menyepakati batas waktu, dan mendokumentasikan koordinasi','Menghubungi penanggung jawab dan menawarkan dukungan'),
('Jejaring kerja','dua rekan berbeda pendapat tentang pembagian tugas','Memfasilitasi pembicaraan berbasis beban kerja dan kompetensi','Mendengarkan kedua pihak sebelum mengusulkan pembagian'),
('Jejaring kerja','rekan baru membutuhkan informasi lintas unit','Menghubungkannya melalui kanal resmi dan menjelaskan batas akses data','Memberi daftar kontak kerja yang relevan'),
('Jejaring kerja','target tim terancam karena satu anggota sakit','Mengatur ulang tugas bersama dan menjaga kapasitas serta privasi rekan','Menawarkan bantuan pada bagian yang paling mendesak'),
('Jejaring kerja','rapat lintas unit menghasilkan kesepakatan yang belum jelas','Merangkum keputusan, pemilik tugas, dan tenggat untuk dikonfirmasi bersama','Mengirim catatan rapat untuk mendapat koreksi'),
('Literasi digital','pesan meminta OTP melalui tautan yang mencurigakan','Tidak membagikan OTP, memverifikasi lewat kanal resmi, dan melaporkan indikasi penipuan','Memeriksa alamat pengirim tanpa membuka tautan'),
('Literasi digital','dokumen kerja sensitif terkirim ke penerima yang keliru','Segera melaporkan insiden dan mengikuti prosedur pembatasan dampak','Menghubungi penanggung jawab keamanan untuk arahan'),
('Literasi digital','aplikasi meminta akses data yang tidak relevan','Memeriksa kebutuhan izin dan menggunakan pilihan akses minimum yang sah','Mencari penjelasan kebijakan privasi sebelum mengizinkan'),
('Literasi digital','berkas bersama diubah tanpa catatan','Memeriksa riwayat versi dan menetapkan proses perubahan terdokumentasi','Mengonfirmasi perubahan dengan anggota tim'),
('Literasi digital','perangkat kerja menampilkan peringatan keamanan','Mengikuti prosedur insiden dan menghubungi dukungan resmi','Menghentikan pekerjaan berisiko sambil mencari bantuan resmi'),
('Antiradikalisme','ajakan grup mengandung kekerasan terhadap kelompok tertentu','Menolak ajakan, tidak menyebarkan, dan melapor melalui kanal yang tepat','Keluar dari percakapan dan menyimpan informasi relevan untuk pelaporan aman'),
('Antiradikalisme','diskusi daring menyebarkan tuduhan tanpa bukti','Memeriksa fakta dan mengajak diskusi yang menghormati hak orang lain','Tidak meneruskan unggahan sambil mencari sumber tepercaya'),
('Antiradikalisme','rekan mengajak mendiskriminasi pengguna karena keyakinan','Menegaskan layanan setara sesuai ketentuan dan melaporkan pelanggaran bila terjadi','Mengingatkan rekan tentang standar nondiskriminasi'),
('Antiradikalisme','materi provokatif muncul di kanal kerja','Mengikuti prosedur moderasi dan pelaporan tanpa memperluas penyebarannya','Meminta pengelola kanal mengevaluasi materi'),
('Adaptasi','layanan harus beralih sementara karena gangguan jaringan','Menerapkan prosedur cadangan resmi, mencatat transaksi, dan memberi informasi jujur','Mengikuti arahan penanggung jawab dan mendokumentasikan hambatan'),
('Adaptasi','penempatan tugas berubah ke unit yang belum dikenal','Memahami kebutuhan unit, menyiapkan transisi, dan meminta arahan yang spesifik','Mempelajari tugas unit baru dari dokumen resmi'),
('Adaptasi','cara kerja lama terbukti kurang efektif','Meninjau bukti, menguji usulan perbaikan terukur, dan mengevaluasi hasil','Mendiskusikan hambatan dengan tim'),
('Adaptasi','tugas mendadak muncul ketika pekerjaan rutin belum selesai','Mengomunikasikan prioritas dan menyusun ulang rencana sesuai tingkat urgensi','Meminta penjelasan tenggat dan dampak tugas baru')]
assert len(scenarios)==38
settings=['Saat bertugas di loket','Dalam tugas rotasi tim','Pada kegiatan layanan keliling','Saat jadwal pelayanan padat','Dalam koordinasi kerja harian']
for setting in settings:
 for topic,problem,best,good in scenarios:
  add('TKP',topic,f'{setting}, {problem}. Tindakan paling tepat adalah …',[best,good,'Menunggu tanpa memberi informasi atau mencari solusi','Mengabaikan masalah karena dianggap bukan tanggung jawab pribadi','Menutupi masalah atau memanfaatkan keadaan demi kepentingan pribadi'],None,f'Pilihan paling kuat: {best}. Respons ini menggabungkan tanggung jawab, ketepatan prosedur, dan kepentingan pengguna. Skor 1–5 adalah rubrik latihan penulis, bukan kunci resmi pemerintah.',[5,4,3,2,1])
assert len(questions)==450,len(questions)
lessons=[]
lesson_defs=[
('TWK','Pancasila','Nilai yang hidup dalam keputusan sehari-hari',12,['Pancasila menjadi dasar negara dan pedoman nilai. Kelima silanya saling berkaitan; contoh kasus dapat melibatkan beberapa sila sekaligus.','Sila pertama: kebebasan beribadah dan toleransi. Sila kedua: martabat manusia serta perlakuan yang adil. Sila ketiga: persatuan dalam keberagaman.','Sila keempat menekankan musyawarah yang mendengar alasan. Sila kelima menekankan keadilan sosial dan pemerataan kesempatan.','Cara belajar: tentukan nilai yang paling dominan dalam kasus. Jangan hanya mencocokkan kata; perhatikan tindakan dan dampaknya.']),
('TWK','Konstitusi','Mengenal UUD NRI Tahun 1945',15,['UUD NRI Tahun 1945 adalah konstitusi Indonesia. Gunakan naskah resmi untuk membaca pasal beserta perubahan-perubahannya.','Pasal 1: Indonesia negara kesatuan berbentuk republik, kedaulatan rakyat dilaksanakan menurut UUD, dan Indonesia negara hukum.','Kenali fungsi lembaga: DPR membentuk undang-undang; BPK memeriksa keuangan negara; MK menguji UU terhadap UUD.','Pasal 31 mengatur pendidikan; Pasal 33 perekonomian; Pasal 34 kesejahteraan sosial. Pahami hubungan prinsip dengan contoh nyata.']),
('TWK','Nasionalisme','Persatuan yang menghormati keragaman',10,['Nasionalisme diwujudkan dengan kontribusi yang jujur, penghormatan keragaman, dan kepentingan bersama.','Bhinneka Tunggal Ika berarti berbeda-beda tetapi tetap satu. Persatuan tidak memerlukan penghapusan identitas budaya.','Sumpah Pemuda 28 Oktober 1928 menegaskan persatuan tanah air, bangsa, dan bahasa. Proklamasi 17 Agustus 1945 merupakan tonggak kemerdekaan.','Dalam soal kasus, utamakan tindakan konstruktif, nondiskriminatif, dan sesuai hukum.']),
('TWK','Bela negara','Tanggung jawab warga di ruang nyata dan digital',10,['Bela negara tidak terbatas pada kegiatan militer. Warga dapat berkontribusi sesuai kemampuan dan profesi.','Menjaga persatuan, menjalankan kewajiban, merawat fasilitas publik, dan membantu saat bencana merupakan contoh kontribusi.','Verifikasi informasi sebelum menyebarkan. Lindungi akun dan data pribadi. Tolak ajakan kekerasan dan gunakan jalur pelaporan resmi.','Latihan: uraikan bagaimana tindakan sehari-hari dapat meningkatkan ketahanan masyarakat.']),
('TIU','Deret angka','Membaca pola sebelum menghitung',12,['Cari selisih antarangka terlebih dahulu. Deret aritmetika memiliki selisih tetap; deret geometri memiliki rasio tetap.','Contoh: 4, 7, 10, 13 memiliki selisih 3. Angka berikutnya 16.','Jika selisih tidak tetap, periksa selisih bertingkat atau pola bergantian. Jangan memaksakan satu rumus.','Tuliskan pola singkat dan verifikasi pada semua suku yang tersedia.']),
('TIU','Persentase','Persentase, rasio, dan ketelitian satuan',15,['Persen berarti per seratus. Diskon p% menghasilkan harga akhir = harga awal × (100 − p)/100.','Perbandingan a:b dengan total T memberi bagian pertama a/(a+b) × T.','Kecepatan = jarak/waktu. Pastikan satuan waktu konsisten sebelum menghitung.','Contoh: rasio 2:3, total 40. Bagian pertama = 2/5 × 40 = 16.']),
('TIU','Aljabar','Memisahkan variabel secara bertahap',12,['Persamaan tetap seimbang bila operasi yang sama diterapkan pada kedua ruas.','Contoh: 3x + 4 = 19. Kurangi 4 pada kedua ruas: 3x = 15. Bagi 3: x = 5.','Periksa jawaban dengan substitusi ke persamaan semula.','Dalam soal cerita, tetapkan variabel dan satuannya sebelum membentuk persamaan.']),
('TIU','Figural','Pola bentuk dan siklus visual',10,['Amati jumlah, posisi, arah, bentuk, dan pola pengulangan. Analisis satu atribut setiap kali.','Jika pola berulang setiap 5 simbol, posisi ke-n ditentukan oleh sisa (n−1) dibagi 5.','Contoh: ○ △ □ ◇ ★ berulang. Posisi ke-7 adalah △.','Paket awal memakai simbol vektor/teks; font perangkat harus mendukung simbol yang ditampilkan.']),
('TKP','Pelayanan publik','Respons yang membantu dan dapat dipertanggungjawabkan',12,['Pelayanan yang baik memadukan empati, kejelasan informasi, ketepatan prosedur, dan tindak lanjut.','Dengarkan kebutuhan, jelaskan pilihan yang sah, dan pastikan pengguna memahami langkah berikutnya.','Hindari janji yang belum pasti, diskriminasi, atau jalan pintas yang melanggar aturan.','Skor TKP di aplikasi merupakan rubrik latihan. Semua opsi mempunyai bobot 1–5; tidak dijawab bernilai 0.']),
('TKP','Integritas','Jujur saat keputusan terasa sulit',12,['Integritas berarti konsisten antara nilai, ucapan, dan tindakan. Dokumentasi membantu menjaga akuntabilitas.','Kelola benturan kepentingan dengan pengungkapan yang relevan dan prosedur resmi.','Jika ada kesalahan, laporkan dan perbaiki dengan jejak koreksi. Jangan menghapus bukti atau menyalahkan orang lain.','Hadiah terkait jabatan ditangani sesuai ketentuan gratifikasi dan prosedur instansi.']),
('TKP','Literasi digital','Layanan aman di lingkungan digital',10,['Gunakan akses minimum yang diperlukan dan lindungi kata sandi serta OTP.','Periksa alamat situs dan gunakan kanal resmi. Pesan mendesak tidak otomatis dapat dipercaya.','Laporkan insiden melalui prosedur yang sesuai; jangan menyebarkan dokumen sensitif untuk meminta pertolongan di grup umum.','Aplikasi ini cukup menyimpan metadata checklist. NIK, KK, dan password SSCASN tidak diperlukan.']),
('TKP','Jejaring kerja','Kolaborasi yang jelas dan inklusif',10,['Kolaborasi efektif memerlukan tujuan, peran, tenggat, dan jalur komunikasi yang jelas.','Dengarkan hambatan pihak lain dan cari solusi berbasis kapasitas serta bukti.','Ringkas keputusan rapat untuk dikonfirmasi. Jaga batas akses data lintas unit.','Perbedaan budaya perlu dihormati; akomodasi yang adil mendukung akses dan kinerja tim.'])]
for i,(d,t,title,minutes,body) in enumerate(lesson_defs): lessons.append({'id':f'lesson-{i+1:02d}','domain':d,'topic':t,'title':title,'minutes':minutes,'body':body,'version':1,'status':'published','review_status':'automated_validation_only'})
packs=[]
by={d:[q['id'] for q in questions if q['domain']==d] for d in ['TWK','TIU','TKP']}
for i in range(3):
 ids=by['TWK'][i*30:(i+1)*30]+by['TIU'][i*35:(i+1)*35]+by['TKP'][i*45:(i+1)*45]
 packs.append({'id':f'cat-2024-{i+1}','name':f'Simulasi CAT {i+1:02d}','question_ids':ids,'duration_seconds':6000,'blueprint':'historical-2024-v1','status':'historical'})
data={'packs':packs,'version':'1.0.0','published_at':'2026-11-20','license':'CC BY 4.0','notice':'Konten original berbasis templat, tervalidasi struktur dan hitungan otomatis. Belum ditinjau ahli materi; bukan soal resmi atau bocoran. Tiga paket CAT berbeda ID dan tanpa tumpang tindih soal. Sebagian pola latihan berulang dengan konteks atau angka berbeda.','questions':questions,'lessons':lessons,'packs':packs}
raw=json.dumps(data,ensure_ascii=False,indent=2).encode(); (ROOT/'assets/content/starter.json').write_bytes(raw)
manifest={'version':data['version'],'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'questions':len(questions),'lessons':len(lessons)}
(ROOT/'assets/content/manifest.json').write_text(json.dumps(manifest,indent=2))
raw=json.dumps(data,ensure_ascii=False,separators=(',',':')).encode()
(ROOT/'assets/content/content.json').write_bytes(raw)
manifest['sha256']=hashlib.sha256(raw).hexdigest()
manifest['bytes']=len(raw)
(ROOT/'assets/content/manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest))
