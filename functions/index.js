const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Function to handle automatic plan matching
exports.autoMatchPlans = functions.firestore
  .document('dining_plans/{planId}')
  .onWrite(async (change, context) => {
    const planId = context.params.planId;
    
    // If document was deleted, nothing to do
    if (!change.after.exists) {
      return null;
    }
    
    const planData = change.after.data();
    
    // Only process if plan is open and not full
    if (planData.status !== 'open' || planData.memberIds.length >= planData.maxMembers) {
      return null;
    }
    
    try {
      // Find compatible users for this plan
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('isActive', '==', true)
        .get();
      
      const compatibleUsers = [];
      
      usersSnapshot.forEach(doc => {
        const userData = doc.data();
        const userId = doc.id;
        
        // Skip if user is already in the plan
        if (planData.memberIds.includes(userId)) {
          return;
        }
        
        // Check company compatibility (different companies only)
        if (userData.company === planData.creatorCompany) {
          return;
        }
        
        // Check cuisine preferences
        const userCuisines = userData.foodPreferences || [];
        const planCuisines = planData.cuisineTypes || [];
        const hasCommonCuisine = userCuisines.some(cuisine => 
          planCuisines.includes(cuisine)
        );
        
        if (hasCommonCuisine) {
          compatibleUsers.push({
            userId,
            userData,
            compatibility: calculateCompatibility(userData, planData)
          });
        }
      });
      
      // Sort by compatibility score
      compatibleUsers.sort((a, b) => b.compatibility - a.compatibility);
      
      // Send notifications to top compatible users
      const notificationPromises = compatibleUsers.slice(0, 5).map(user => 
        sendPlanRecommendation(user.userId, planId, planData)
      );
      
      await Promise.all(notificationPromises);
      
      console.log(`Sent plan recommendations for ${planId} to ${compatibleUsers.length} users`);
      
    } catch (error) {
      console.error('Error in autoMatchPlans:', error);
    }
    
    return null;
  });

// Cloud Function to generate arrival codes
exports.generateArrivalCodes = functions.firestore
  .document('dining_plans/{planId}')
  .onUpdate(async (change, context) => {
    const planId = context.params.planId;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    // Check if plan just became full
    if (beforeData.memberIds.length < afterData.maxMembers && 
        afterData.memberIds.length === afterData.maxMembers &&
        afterData.status === 'matched') {
      
      try {
        // Generate unique codes for each member
        const codes = generateUniqueCodes(afterData.memberIds.length);
        const codeAssignments = {};
        
        afterData.memberIds.forEach((memberId, index) => {
          codeAssignments[memberId] = codes[index];
        });
        
        // Update the plan with arrival codes
        await admin.firestore()
          .collection('dining_plans')
          .doc(planId)
          .update({
            arrivalCodes: codeAssignments,
            status: 'confirmed',
            confirmedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        
        // Send notifications to all members with their codes
        const notificationPromises = afterData.memberIds.map(memberId =>
          sendArrivalCode(memberId, planId, codeAssignments[memberId], afterData)
        );
        
        await Promise.all(notificationPromises);
        
        console.log(`Generated arrival codes for plan ${planId}`);
        
      } catch (error) {
        console.error('Error generating arrival codes:', error);
      }
    }
    
    return null;
  });

// Cloud Function to handle user ratings and update trust scores
exports.updateTrustScores = functions.firestore
  .document('ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const ratingData = snap.data();
    
    if (ratingData.ratedUserId && ratingData.userRating) {
      try {
        const userRef = admin.firestore().collection('users').doc(ratingData.ratedUserId);
        const userDoc = await userRef.get();
        
        if (userDoc.exists) {
          const userData = userDoc.data();
          const currentTrustScore = userData.trustScore || 0;
          const ratingCount = userData.ratingCount || 0;
          
          // Calculate new trust score (weighted average)
          const newTrustScore = ((currentTrustScore * ratingCount) + ratingData.userRating) / (ratingCount + 1);
          
          await userRef.update({
            trustScore: newTrustScore,
            ratingCount: ratingCount + 1,
            lastRatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          console.log(`Updated trust score for user ${ratingData.ratedUserId}: ${newTrustScore}`);
        }
      } catch (error) {
        console.error('Error updating trust score:', error);
      }
    }
    
    return null;
  });

// Cloud Function to send scheduled notifications
exports.sendScheduledNotifications = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
    
    try {
      // Find plans starting within the next hour
      const upcomingPlansSnapshot = await admin.firestore()
        .collection('dining_plans')
        .where('status', '==', 'confirmed')
        .where('plannedTime', '>=', now)
        .where('plannedTime', '<=', oneHourFromNow)
        .get();
      
      const reminderPromises = [];
      
      upcomingPlansSnapshot.forEach(doc => {
        const planData = doc.data();
        const planId = doc.id;
        
        // Send reminder to each member
        planData.memberIds.forEach(memberId => {
          reminderPromises.push(
            sendArrivalReminder(memberId, planId, planData)
          );
        });
      });
      
      await Promise.all(reminderPromises);
      
      console.log(`Sent ${reminderPromises.length} arrival reminders`);
      
    } catch (error) {
      console.error('Error sending scheduled notifications:', error);
    }
    
    return null;
  });

// Cloud Function to clean up expired plans
exports.cleanupExpiredPlans = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    try {
      // Find expired plans
      const expiredPlansSnapshot = await admin.firestore()
        .collection('dining_plans')
        .where('plannedTime', '<', yesterday)
        .where('status', 'in', ['open', 'matched'])
        .get();
      
      const batch = admin.firestore().batch();
      
      expiredPlansSnapshot.forEach(doc => {
        batch.update(doc.ref, {
          status: 'expired',
          expiredAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      
      console.log(`Marked ${expiredPlansSnapshot.size} plans as expired`);
      
    } catch (error) {
      console.error('Error cleaning up expired plans:', error);
    }
    
    return null;
  });

// Helper Functions

function calculateCompatibility(userData, planData) {
  let score = 0;
  
  // Cuisine preference match (40% weight)
  const userCuisines = userData.foodPreferences || [];
  const planCuisines = planData.cuisineTypes || [];
  const commonCuisines = userCuisines.filter(cuisine => planCuisines.includes(cuisine));
  score += (commonCuisines.length / Math.max(userCuisines.length, 1)) * 40;
  
  // Trust score (30% weight)
  const trustScore = userData.trustScore || 0;
  score += (trustScore / 5) * 30;
  
  // Premium status (20% weight)
  if (userData.isPremium) {
    score += 20;
  }
  
  // Activity level (10% weight)
  const recentActivity = userData.lastActiveAt || new Date(0);
  const daysSinceActive = (Date.now() - recentActivity.toDate().getTime()) / (1000 * 60 * 60 * 24);
  score += Math.max(0, (7 - daysSinceActive) / 7) * 10;
  
  return score;
}

function generateUniqueCodes(count) {
  const codes = [];
  const usedCodes = new Set();
  
  while (codes.length < count) {
    const code = Math.floor(Math.random() * 90) + 10; // 2-digit code (10-99)
    if (!usedCodes.has(code)) {
      codes.push(code);
      usedCodes.add(code);
    }
  }
  
  return codes;
}

async function sendPlanRecommendation(userId, planId, planData) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (userData.fcmToken) {
      const message = {
        token: userData.fcmToken,
        notification: {
          title: '🍽️ Perfect Dining Match Found!',
          body: `Join a dining plan at ${planData.restaurantName} - ${planData.cuisineTypes.join(', ')}`
        },
        data: {
          type: 'plan_recommendation',
          planId: planId,
          restaurantName: planData.restaurantName
        }
      };
      
      await admin.messaging().send(message);
    }
  } catch (error) {
    console.error(`Error sending plan recommendation to ${userId}:`, error);
  }
}

async function sendArrivalCode(userId, planId, code, planData) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (userData.fcmToken) {
      const message = {
        token: userData.fcmToken,
        notification: {
          title: '🎉 Your Dining Plan is Confirmed!',
          body: `Your arrival code is ${code}. Show this at ${planData.restaurantName}`
        },
        data: {
          type: 'arrival_code',
          planId: planId,
          arrivalCode: code.toString(),
          restaurantName: planData.restaurantName
        }
      };
      
      await admin.messaging().send(message);
    }
  } catch (error) {
    console.error(`Error sending arrival code to ${userId}:`, error);
  }
}

async function sendArrivalReminder(userId, planId, planData) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (userData.fcmToken) {
      const message = {
        token: userData.fcmToken,
        notification: {
          title: '⏰ Dining Plan Reminder',
          body: `Your dining plan at ${planData.restaurantName} starts in 1 hour!`
        },
        data: {
          type: 'arrival_reminder',
          planId: planId,
          restaurantName: planData.restaurantName
        }
      };
      
      await admin.messaging().send(message);
    }
  } catch (error) {
    console.error(`Error sending arrival reminder to ${userId}:`, error);
  }
}