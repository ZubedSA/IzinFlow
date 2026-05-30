import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // 1. Create a Default Platform Organization for Super Admins
  const systemOrg = await prisma.organization.upsert({
    where: { slug: 'system' },
    update: {},
    create: {
      name: 'IzinFlow Platform Headquarter',
      slug: 'system',
      brandColor: '#00A86B',
      address: 'DKI Jakarta, Indonesia',
      contact: 'support@izinflow.com',
    },
  });
  console.log(`✅ Organization created/verified: ${systemOrg.name} (${systemOrg.id})`);

  // 2. Create the platform Super Admin Account
  const superAdminEmail = 'admin@izinflow.com';
  const existingSuperAdmin = await prisma.user.findFirst({
    where: { email: superAdminEmail },
  });

  if (!existingSuperAdmin) {
    const passwordHash = await bcrypt.hash('izinflow123', 10);
    const superAdmin = await prisma.user.create({
      data: {
        organizationId: systemOrg.id,
        email: superAdminEmail,
        passwordHash,
        role: UserRole.SUPER_ADMIN,
        fullName: 'Super Administrator',
      },
    });
    console.log(`✅ Super Admin created: ${superAdmin.email}`);
  } else {
    console.log('ℹ️ Super Admin already exists.');
  }

  // 3. Create a Demo School Organization (SMP Maju Jaya)
  const schoolOrg = await prisma.organization.upsert({
    where: { slug: 'smp-majujaya' },
    update: {},
    create: {
      name: 'SMP Negeri 1 Maju Jaya',
      slug: 'smp-majujaya',
      brandColor: '#004D40',
      address: 'Jl. Pemuda No. 12, Bandung',
      contact: 'info@smpmajujaya.sch.id',
    },
  });
  console.log(`✅ Demo Organization created: ${schoolOrg.name}`);

  // 4. Create Homeroom Class Room
  const classRoom = await prisma.classRoom.upsert({
    where: {
      organizationId_name: {
        organizationId: schoolOrg.id,
        name: 'XII IPA 1',
      },
    },
    update: {},
    create: {
      organizationId: schoolOrg.id,
      name: 'XII IPA 1',
    },
  });
  console.log(`✅ Demo ClassRoom created: ${classRoom.name}`);

  // 5. Create Teacher & Student for testing
  const teacherEmail = 'teacher@majujaya.sch.id';
  const existingTeacher = await prisma.user.findFirst({
    where: { email: teacherEmail },
  });

  if (!existingTeacher) {
    const passwordHash = await bcrypt.hash('teacher123', 10);
    const teacherUser = await prisma.user.create({
      data: {
        organizationId: schoolOrg.id,
        email: teacherEmail,
        passwordHash,
        role: UserRole.TEACHER,
        fullName: 'Budi Darmawan, S.Pd.',
      },
    });

    const teacher = await prisma.teacher.create({
      data: {
        organizationId: schoolOrg.id,
        userId: teacherUser.id,
        employeeNumber: '197608122003121002',
      },
    });

    // Update Classroom homeroom teacher
    await prisma.classRoom.update({
      where: { id: classRoom.id },
      data: { homeroomTeacherId: teacher.id },
    });

    console.log(`✅ Demo Teacher created: ${teacherUser.fullName}`);
  }

  const studentEmail = 'student@majujaya.sch.id';
  const existingStudent = await prisma.user.findFirst({
    where: { email: studentEmail },
  });

  if (!existingStudent) {
    const passwordHash = await bcrypt.hash('student123', 10);
    const studentUser = await prisma.user.create({
      data: {
        organizationId: schoolOrg.id,
        email: studentEmail,
        passwordHash,
        role: UserRole.STUDENT,
        fullName: 'Ahmad Setiawan',
      },
    });

    await prisma.student.create({
      data: {
        organizationId: schoolOrg.id,
        userId: studentUser.id,
        classRoomId: classRoom.id,
        studentIdNumber: '0098765421',
      },
    });

    console.log(`✅ Demo Student created: ${studentUser.fullName}`);
  }

  console.log('🌱 Seeding process completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
